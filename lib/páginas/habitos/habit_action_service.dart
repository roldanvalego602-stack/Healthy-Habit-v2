import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../niveles/levels_system.dart';
import 'catalogo.dart';
import 'modelo/habit.dart';

/// Operaciones compartidas entre Hábitos y Mr. Healthy.
/// La interfaz nunca concede XP, fuerza desbloqueos ni cambia saldos.
class HabitActionService {
  const HabitActionService();

  static const int initialSlots = 3;
  static const int difficultCancellationLimit = 25;

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(), databaseId: 'default');

  DocumentReference<Map<String, dynamic>> get _userRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Inicia sesión para administrar tus hábitos.');
    }
    return _db.collection('users').doc(uid);
  }

  static int number(Object? raw, [int fallback = 0]) =>
      raw is num ? raw.toInt() : int.tryParse('$raw') ?? fallback;

  static bool isDifficult(Habit habit) {
    final difficulty = habit.difficulty.toLowerCase();
    return difficulty == 'difícil' || difficulty == 'dificil';
  }

  static Habit? findCatalogHabit(String nameOrId) {
    final text = nameOrId.trim().toLowerCase();
    for (final h in habitCatalog) {
      if ((h['id'] as String).toLowerCase() == text ||
          (h['title'] as String).trim().toLowerCase() == text) {
        return Habit.fromMap(Map<String, dynamic>.from(h), h['id'] as String);
      }
    }
    return null;
  }

  static bool isUnlocked(Habit habit, {
    required int xp,
    required int coins,
    required Set<String> activeIds,
  }) {
    final level = LevelSystem.fromXp(xp).number;
    switch (habit.unlockType.trim().toLowerCase()) {
      case 'none':
      case 'free':
        return true;
      case 'level':
        return level >= (habit.requiredLevel ?? 1);
      case 'coins':
        return coins >= habit.coinCost;
      case 'habit':
        return activeIds.contains(habit.requiredHabitId);
      case 'combined':
        return level >= (habit.requiredLevel ?? 1) &&
            coins >= habit.coinCost &&
            (habit.requiredHabitId == null ||
                activeIds.contains(habit.requiredHabitId));
      default:
        return false;
    }
  }

  static int cancellationFee(Habit habit, int coins) =>
      isDifficult(habit)
          ? coins.clamp(0, difficultCancellationLimit).toInt()
          : 0;

  /// Revisa los cupos y estados reales antes de pedir confirmación al usuario.
  Future<HabitActionPreview> preview(String habitId, {
    required bool remove,
  }) async {
    final habit = findCatalogHabit(habitId);
    if (habit == null) {
      throw StateError('Ese hábito no pertenece al catálogo oficial.');
    }
    final userRef = _userRef;
    final userSnapshot = await userRef.get();
    if (!userSnapshot.exists) {
      throw StateError('No se encontró tu perfil. Vuelve a iniciar sesión.');
    }
    final info = userSnapshot.data()!;
    final coins = number(info['habitCoins']);
    final xp = number(info['xp'] ?? info['currentXp']);
    final slots = number(info['habitSlots'], initialSlots).clamp(1, 100).toInt();

    final docs = await userRef.collection('user_habits').get();
    final attempts = await Future.wait(docs.docs.map((doc) =>
        doc.reference.collection('attempts')
            .where('status', isEqualTo: 'inProgress').get()));
    final active = <String, String>{};
    for (var i = 0; i < docs.docs.length; i++) {
      if (attempts[i].docs.isNotEmpty) {
        active[docs.docs[i].id] = attempts[i].docs.first.id;
      }
    }
    if (remove) {
      if (!active.containsKey(habit.id)) {
        throw StateError('Ese hábito no tiene un intento activo.');
      }
    } else {
      if (active.containsKey(habit.id)) {
        throw StateError('Ese hábito ya está en progreso.');
      }
      if (active.length >= slots) {
        throw StateError('Ya ocupaste tus $slots espacios disponibles.');
      }
      if (!isUnlocked(habit, xp: xp, coins: coins,
          activeIds: active.keys.toSet())) {
        throw StateError('Todavía no cumples los requisitos del hábito.');
      }
      if (habit.coinCost > coins) {
        throw StateError('No tienes suficientes Habit Coins.');
      }
      final previous = docs.docs.where((d) => d.id == habit.id);
      if (previous.isNotEmpty) {
        final data = previous.first.data();
        if (data['lastStatus'] == 'completed' && !habit.repeatable) {
          throw StateError('Este hábito no se puede repetir.');
        }
        final lastId = data['lastAttemptId']?.toString();
        if (lastId != null && lastId.isNotEmpty) {
          final last = await previous.first.reference
              .collection('attempts').doc(lastId).get();
          final until = last.data()?['availableAgainAt'];
          if (until is Timestamp && until.toDate().isAfter(DateTime.now())) {
            throw StateError('Este hábito aún está en periodo de espera.');
          }
        }
      }
    }

    return HabitActionPreview(
      habit: habit,
      remove: remove,
      attemptId: remove ? active[habit.id] : null,
      activeCount: active.length,
      activeIds: active.keys.toSet(),
      slots: slots,
      xp: xp,
      coins: coins,
      mutationVersion: number(info['habitMutationVersion']),
      estimatedCost: remove
          ? cancellationFee(habit, coins)
          : habit.coinCost,
    );
  }

  /// El diálogo de confirmación debe ocurrir ANTES de invocar esta función.
  /// El contador de versión protege dos solicitudes simultáneas del asistente
  /// o la pantalla frente a cupos obsoletos.
  Future<HabitActionResult> execute(HabitActionPreview preview) async {
    final userRef = _userRef;
    final habit = preview.habit;
    final habitRef = userRef.collection('user_habits').doc(habit.id);
    final attemptsRef = habitRef.collection('attempts');

    if (preview.remove) {
      final id = preview.attemptId;
      if (id == null) throw StateError('Falta identificar el intento activo.');
      final attemptRef = attemptsRef.doc(id);
      final fee = await _db.runTransaction<int>((tx) async {
        final userSnap = await tx.get(userRef);
        final habitSnap = await tx.get(habitRef);
        final attemptSnap = await tx.get(attemptRef);
        final userData = userSnap.data() ?? {};
        if (number(userData['habitMutationVersion']) !=
            preview.mutationVersion) {
          throw StateError('Tus hábitos cambiaron. Solicita una vista nueva.');
        }
        if (!attemptSnap.exists ||
            attemptSnap.data()?['status'] != 'inProgress' ||
            habitSnap.data()?['lastAttemptId'] != id) {
          throw StateError('Este intento ya no está activo.');
        }
        final coins = number(userData['habitCoins']).clamp(0, 1000000000).toInt();
        final deducted = cancellationFee(habit, coins);
        tx.update(attemptRef, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancellationPenalty': deducted,
        });
        tx.update(habitRef, {
          'lastStatus': 'cancelled',
          'latestStatus': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        tx.update(userRef, {
          'habitCoins': coins - deducted,
          'habitMutationVersion': preview.mutationVersion + 1,
        });
        return deducted;
      });
      return HabitActionResult(
        habit: habit, removed: true, chargedCoins: fee);
    }

    final previousAttempts = await attemptsRef.get();
    final attemptNumber = previousAttempts.docs.length + 1;
    final attemptRef = attemptsRef.doc();
    final now = DateTime.now();
    final attempt = UserHabit(
      id: attemptRef.id,
      habitId: habit.id,
      status: UserHabitStatus.inProgress,
      progress: 0,
      target: habit.target,
      attemptNumber: attemptNumber,
      xpEarned: 0,
      acquiredAt: now,
      frequencyType: habit.frequencyType,
      registrationsPerPeriod: habit.registrationsPerPeriod,
      durationPeriods: habit.durationPeriods,
      gracePeriods: habit.gracePeriods,
      streakEnabled: habit.streakEnabled,
    );
    final charged = await _db.runTransaction<int>((tx) async {
      final userSnap = await tx.get(userRef);
      final habitSnap = await tx.get(habitRef);
      final data = userSnap.data() ?? {};
      if (!userSnap.exists ||
          number(data['habitMutationVersion']) != preview.mutationVersion) {
        throw StateError('Tus hábitos cambiaron. Solicita una vista nueva.');
      }
      final xp = number(data['xp'] ?? data['currentXp']);
      final coins = number(data['habitCoins']).clamp(0, 1000000000).toInt();
      final slots = number(data['habitSlots'], initialSlots);
      if (preview.activeCount >= slots ||
          !isUnlocked(habit, xp: xp, coins: coins,
              activeIds: preview.activeIds) ||
          coins < habit.coinCost) {
        throw StateError('Ya no cumples los requisitos de activación.');
      }
      if (habitSnap.data()?['lastStatus'] == 'inProgress' ||
          habitSnap.data()?['latestStatus'] == 'inProgress' ||
          habitSnap.data()?['lastStatus'] == 'completed' && !habit.repeatable) {
        throw StateError('Este hábito ya está activo o no es repetible.');
      }
      // Se vuelven a validar las condiciones para evitar gastar monedas con
      // información obsoleta. No se usa un batch sin verificación.
      tx.set(userRef, {
        'habitCoins': coins - habit.coinCost,
        'habitSlots': slots,
        'habitMutationVersion': preview.mutationVersion + 1,
      }, SetOptions(merge: true));
      tx.set(habitRef, {
        ...habit.toMap(),
        'acquiredAt': FieldValue.serverTimestamp(),
        'lastAttemptId': attemptRef.id,
        'lastStatus': 'inProgress',
        'latestStatus': 'inProgress',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(attemptRef, attempt.toMap());
      return habit.coinCost;
    });
    return HabitActionResult(
      habit: habit, removed: false, chargedCoins: charged);
  }
}

class HabitActionPreview {
  const HabitActionPreview({
    required this.habit,
    required this.remove,
    required this.attemptId,
    required this.activeCount,
    required this.activeIds,
    required this.slots,
    required this.xp,
    required this.coins,
    required this.mutationVersion,
    required this.estimatedCost,
  });
  final Habit habit;
  final bool remove;
  final String? attemptId;
  final int activeCount;
  final Set<String> activeIds;
  final int slots;
  final int xp;
  final int coins;
  final int mutationVersion;
  final int estimatedCost;
}

class HabitActionResult {
  const HabitActionResult({
    required this.habit,
    required this.removed,
    required this.chargedCoins,
  });
  final Habit habit;
  final bool removed;
  final int chargedCoins;
}

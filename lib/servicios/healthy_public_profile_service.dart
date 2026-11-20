import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Proyección EXCLUSIVAMENTE pública del perfil.
///
/// Se sincroniza al entrar en la app y al cambiar el documento privado.
/// No copiar correo, fecha de nacimiento, preferencias privadas, inventario,
/// historial, fotografías de evidencias o datos de autenticación.
class HealthyPublicProfileService {
  HealthyPublicProfileService._();

  static final HealthyPublicProfileService instance =
      HealthyPublicProfileService._();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  String? _activeUid;
  String? _lastProjectionJson;

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'default');

  void start() {
    if (_authSubscription != null) return;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(_watchUser);
  }

  void _watchUser(User? user) {
    _userSubscription?.cancel();
    _userSubscription = null;
    _activeUid = user?.uid;
    _lastProjectionJson = null;
    if (user == null) return;

    final uid = user.uid;
    _userSubscription = _db.collection('users').doc(uid).snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists || _activeUid != uid) return;
        final projection = project(snapshot.data() ?? {});
        final projectionJson = jsonEncode(projection);
        if (_lastProjectionJson == projectionJson) return;
        try {
          // El ID es el UID autenticado: las reglas no permiten editar otros.
          await _db.collection('public_profiles').doc(uid).set(projection);
          if (_activeUid == uid) _lastProjectionJson = projectionJson;
        } catch (error) {
          debugPrint('Perfil público: no se pudo sincronizar: $error');
        }
      },
      onError: (Object error) =>
          debugPrint('Perfil público: lectura fallida: $error'),
    );
  }

  @visibleForTesting
  static Map<String, dynamic> project(Map<String, dynamic> privateData) {
    String stringValue(String key, String fallback, {int maxLength = 120}) {
      final raw = privateData[key];
      final value = raw is String ? raw.trim() : '';
      final sanitized = value.isEmpty ? fallback : value;
      return sanitized.length > maxLength
          ? sanitized.substring(0, maxLength)
          : sanitized;
    }

    int positiveInt(String key, int fallback) {
      final raw = privateData[key];
      if (raw is! num) return fallback;
      return raw.toInt().clamp(0, 1000000000);
    }

    final rawSettings = privateData['settings'];
    final settings = rawSettings is Map ? rawSettings : <String, dynamic>{};
    final visibility = settings['visibilidadLogros'];
    final achievementsVisibility =
        visibility == 'Todos' || visibility == 'Solo yo' || visibility == 'Solo amigos'
            ? visibility
            : 'Solo amigos';

    return {
      'name': stringValue('name', 'Usuario'),
      'username': stringValue('username', 'usuario'),
      'photoUrl': stringValue('photoUrl', '', maxLength: 2048),
      'bio': stringValue('bio', '', maxLength: 300),
      'title': stringValue('title', 'Cultivador de constancia'),
      'xp': positiveInt('xp', positiveInt('currentXp', 0)),
      'currentXp': positiveInt('currentXp', positiveInt('xp', 0)),
      'level': positiveInt('level', 1),
      'currentStreak': positiveInt('currentStreak', 0),
      'streakDays': positiveInt('streakDays', 0),
      'completedHabits': positiveInt('completedHabits', 0),
      'nextLevelXp': positiveInt('nextLevelXp', 1000),
      'nextAchievementTitle': stringValue('nextAchievementTitle', ''),
      'nextAchievementProgress': privateData['nextAchievementProgress'] is num
          ? (privateData['nextAchievementProgress'] as num).clamp(0, 1)
          : 0,
      // Sólo estas dos preferencias controlan información pública.
      'settings': {
        'mostrarRachaAmigos': settings['mostrarRachaAmigos'] != false,
        'visibilidadLogros': achievementsVisibility,
      },
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class HabitFrequency {
  static const String daily = 'daily';
  static const String weekly = 'weekly';
}

/// Definición de un hábito del catálogo.
class Habit {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String subtitle;

  /// Total de registros necesarios para completar el hábito.
  final int xp;
  final int target;

  final String unlockType;
  final int? requiredLevel;
  final String? requiredHabitId;
  final int coinCost;

  final bool repeatable;
  final int cooldownDays;

  /// Reglas de frecuencia y duración.
  final String frequencyType;
  final int registrationsPerPeriod;
  final int durationPeriods;
  final int gracePeriods;
  final bool streakEnabled;

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.subtitle,
    required this.xp,
    required this.target,
    this.unlockType = 'none',
    this.requiredLevel,
    this.requiredHabitId,
    this.coinCost = 0,
    this.repeatable = true,
    this.cooldownDays = 0,
    this.frequencyType = HabitFrequency.daily,
    this.registrationsPerPeriod = 1,
    this.durationPeriods = 1,
    this.gracePeriods = 1,
    this.streakEnabled = true,
  }) : assert(target > 0),
       assert(xp >= 0),
       assert(coinCost >= 0),
       assert(cooldownDays >= 0),
       assert(registrationsPerPeriod > 0),
       assert(durationPeriods > 0),
       assert(gracePeriods >= 0),
       assert(
         frequencyType == HabitFrequency.daily ||
             frequencyType == HabitFrequency.weekly,
       );

  factory Habit.fromMap(Map<String, dynamic> map, String id) {
    final frequency = map['frequencyType']?.toString() ?? HabitFrequency.daily;

    return Habit(
      id: id,
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? 'Sencillo',
      subtitle: map['subtitle']?.toString() ?? '',
      xp: _readInt(map['xp'], 0),
      target: _readInt(map['target'], 1),
      unlockType: map['unlockType']?.toString() ?? 'none',
      requiredLevel:
          map['requiredLevel'] == null
              ? null
              : _readInt(map['requiredLevel'], 1),
      requiredHabitId: map['requiredHabitId']?.toString(),
      coinCost: _readInt(map['coinCost'], 0),
      repeatable: map['repeatable'] as bool? ?? true,
      cooldownDays: _readInt(map['cooldownDays'], 0),
      frequencyType:
          frequency == HabitFrequency.weekly
              ? HabitFrequency.weekly
              : HabitFrequency.daily,
      registrationsPerPeriod: _readInt(map['registrationsPerPeriod'], 1),
      durationPeriods: _readInt(map['durationPeriods'], 1),
      gracePeriods: _readInt(map['gracePeriods'], 1),
      streakEnabled: map['streakEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'subtitle': subtitle,
      'xp': xp,
      'target': target,
      'unlockType': unlockType,
      'requiredLevel': requiredLevel,
      'requiredHabitId': requiredHabitId,
      'coinCost': coinCost,
      'repeatable': repeatable,
      'cooldownDays': cooldownDays,
      'frequencyType': frequencyType,
      'registrationsPerPeriod': registrationsPerPeriod,
      'durationPeriods': durationPeriods,
      'gracePeriods': gracePeriods,
      'streakEnabled': streakEnabled,
    };
  }
}

enum UserHabitStatus { inProgress, completed, cancelled }

/// Estado de un intento adquirido por el usuario.
class UserHabit {
  final String id;
  final String habitId;
  final UserHabitStatus status;

  /// Progreso acumulado durante todo el intento.
  final int progress;
  final int target;
  final int attemptNumber;
  final int xpEarned;

  final DateTime acquiredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? availableAgainAt;

  /// Copia de las reglas vigentes al adquirir el hábito.
  final String frequencyType;
  final int registrationsPerPeriod;
  final int durationPeriods;
  final int gracePeriods;
  final bool streakEnabled;

  /// Progreso dentro del periodo actual.
  final int periodProgress;

  /// Información de rachas y periodos.
  final int streak;
  final int longestStreak;
  final int missedPeriods;
  final int pendingRecoveries;

  final DateTime? lastRegisteredAt;
  final DateTime? nextAvailableAt;

  /// Identificador del último periodo procesado.
  final String? lastPeriodKey;

  const UserHabit({
    required this.id,
    required this.habitId,
    required this.status,
    required this.progress,
    required this.target,
    required this.attemptNumber,
    required this.xpEarned,
    required this.acquiredAt,
    this.completedAt,
    this.cancelledAt,
    this.availableAgainAt,
    this.frequencyType = HabitFrequency.daily,
    this.registrationsPerPeriod = 1,
    this.durationPeriods = 1,
    this.gracePeriods = 1,
    this.streakEnabled = true,
    this.periodProgress = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.missedPeriods = 0,
    this.pendingRecoveries = 0,
    this.lastRegisteredAt,
    this.nextAvailableAt,
    this.lastPeriodKey,
  }) : assert(progress >= 0),
       assert(target > 0),
       assert(attemptNumber > 0),
       assert(xpEarned >= 0),
       assert(registrationsPerPeriod > 0),
       assert(durationPeriods > 0),
       assert(gracePeriods >= 0),
       assert(periodProgress >= 0),
       assert(streak >= 0),
       assert(longestStreak >= 0),
       assert(missedPeriods >= 0),
       assert(pendingRecoveries >= 0);

  bool get isInProgress => status == UserHabitStatus.inProgress;

  bool get isCompleted => status == UserHabitStatus.completed;

  bool get isCancelled => status == UserHabitStatus.cancelled;

  bool get hasReachedGoal => progress >= target;

  bool get hasPendingRecoveries => pendingRecoveries > 0;

  int get remainingProgress => (target - progress).clamp(0, target);

  factory UserHabit.fromMap(Map<String, dynamic> map, String id) {
    final frequency = map['frequencyType']?.toString() ?? HabitFrequency.daily;

    return UserHabit(
      id: id,
      habitId: map['habitId']?.toString() ?? '',
      status: _readStatus(map['status']),
      progress: _readInt(map['progress'], 0),
      target: _readInt(map['target'], 1),
      attemptNumber: _readInt(map['attemptNumber'], 1),
      xpEarned: _readInt(map['xpEarned'], 0),
      acquiredAt: _readDate(map['acquiredAt']) ?? DateTime.now(),
      completedAt: _readDate(map['completedAt']),
      cancelledAt: _readDate(map['cancelledAt']),
      availableAgainAt: _readDate(map['availableAgainAt']),
      frequencyType:
          frequency == HabitFrequency.weekly
              ? HabitFrequency.weekly
              : HabitFrequency.daily,
      registrationsPerPeriod: _readInt(map['registrationsPerPeriod'], 1),
      durationPeriods: _readInt(map['durationPeriods'], 1),
      gracePeriods: _readInt(map['gracePeriods'], 1),
      streakEnabled: map['streakEnabled'] as bool? ?? true,
      periodProgress: _readInt(map['periodProgress'], 0),
      streak: _readInt(map['streak'], 0),
      longestStreak: _readInt(map['longestStreak'], 0),
      missedPeriods: _readInt(map['missedPeriods'], 0),
      pendingRecoveries: _readInt(map['pendingRecoveries'], 0),
      lastRegisteredAt: _readDate(map['lastRegisteredAt']),
      nextAvailableAt: _readDate(map['nextAvailableAt']),
      lastPeriodKey: map['lastPeriodKey']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'status': status.name,
      'progress': progress,
      'target': target,
      'attemptNumber': attemptNumber,
      'xpEarned': xpEarned,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
      'completedAt': _dateToTimestamp(completedAt),
      'cancelledAt': _dateToTimestamp(cancelledAt),
      'availableAgainAt': _dateToTimestamp(availableAgainAt),
      'frequencyType': frequencyType,
      'registrationsPerPeriod': registrationsPerPeriod,
      'durationPeriods': durationPeriods,
      'gracePeriods': gracePeriods,
      'streakEnabled': streakEnabled,
      'periodProgress': periodProgress,
      'streak': streak,
      'longestStreak': longestStreak,
      'missedPeriods': missedPeriods,
      'pendingRecoveries': pendingRecoveries,
      'lastRegisteredAt': _dateToTimestamp(lastRegisteredAt),
      'nextAvailableAt': _dateToTimestamp(nextAvailableAt),
      'lastPeriodKey': lastPeriodKey,
    };
  }

  UserHabit copyWith({
    UserHabitStatus? status,
    int? progress,
    int? target,
    int? attemptNumber,
    int? xpEarned,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? availableAgainAt,
    String? frequencyType,
    int? registrationsPerPeriod,
    int? durationPeriods,
    int? gracePeriods,
    bool? streakEnabled,
    int? periodProgress,
    int? streak,
    int? longestStreak,
    int? missedPeriods,
    int? pendingRecoveries,
    DateTime? lastRegisteredAt,
    DateTime? nextAvailableAt,
    String? lastPeriodKey,
  }) {
    return UserHabit(
      id: id,
      habitId: habitId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      xpEarned: xpEarned ?? this.xpEarned,
      acquiredAt: acquiredAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      availableAgainAt: availableAgainAt ?? this.availableAgainAt,
      frequencyType: frequencyType ?? this.frequencyType,
      registrationsPerPeriod:
          registrationsPerPeriod ?? this.registrationsPerPeriod,
      durationPeriods: durationPeriods ?? this.durationPeriods,
      gracePeriods: gracePeriods ?? this.gracePeriods,
      streakEnabled: streakEnabled ?? this.streakEnabled,
      periodProgress: periodProgress ?? this.periodProgress,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      missedPeriods: missedPeriods ?? this.missedPeriods,
      pendingRecoveries: pendingRecoveries ?? this.pendingRecoveries,
      lastRegisteredAt: lastRegisteredAt ?? this.lastRegisteredAt,
      nextAvailableAt: nextAvailableAt ?? this.nextAvailableAt,
      lastPeriodKey: lastPeriodKey ?? this.lastPeriodKey,
    );
  }
}

int _readInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Timestamp? _dateToTimestamp(DateTime? date) {
  return date == null ? null : Timestamp.fromDate(date);
}

UserHabitStatus _readStatus(dynamic value) {
  switch (value?.toString()) {
    case 'completed':
      return UserHabitStatus.completed;
    case 'cancelled':
      return UserHabitStatus.cancelled;
    default:
      return UserHabitStatus.inProgress;
  }
}

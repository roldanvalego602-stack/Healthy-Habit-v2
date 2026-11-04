import 'package:cloud_firestore/cloud_firestore.dart';

/// Definición de un hábito disponible en el catálogo.
class Habit {
  final String id;
  final String title;
  final String category;
  final String difficulty;
  final String subtitle;

  final int xp;
  final int target;

  final String unlockType;
  final int? requiredLevel;
  final String? requiredHabitId;
  final int coinCost;

  final bool repeatable;
  final int cooldownDays;

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
  }) : assert(target > 0),
       assert(xp >= 0),
       assert(coinCost >= 0),
       assert(cooldownDays >= 0);

  factory Habit.fromMap(Map<String, dynamic> map, String id) {
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
    };
  }
}

/// Estado de un hábito adquirido por el usuario.
enum UserHabitStatus { inProgress, completed, cancelled }

class UserHabit {
  final String id;
  final String habitId;

  final UserHabitStatus status;

  final int progress;
  final int target;
  final int attemptNumber;
  final int xpEarned;

  final DateTime acquiredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? availableAgainAt;

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
  }) : assert(progress >= 0),
       assert(target > 0),
       assert(attemptNumber > 0),
       assert(xpEarned >= 0);

  bool get isInProgress => status == UserHabitStatus.inProgress;

  bool get isCompleted => status == UserHabitStatus.completed;

  bool get isCancelled => status == UserHabitStatus.cancelled;

  bool get hasReachedGoal => progress >= target;

  factory UserHabit.fromMap(Map<String, dynamic> map, String id) {
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
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'cancelledAt':
          cancelledAt == null ? null : Timestamp.fromDate(cancelledAt!),
      'availableAgainAt':
          availableAgainAt == null
              ? null
              : Timestamp.fromDate(availableAgainAt!),
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

UserHabitStatus _readStatus(dynamic value) {
  switch (value?.toString()) {
    case 'completed':
      return UserHabitStatus.completed;
    case 'cancelled':
      return UserHabitStatus.cancelled;
    case 'inProgress':
    default:
      return UserHabitStatus.inProgress;
  }
}

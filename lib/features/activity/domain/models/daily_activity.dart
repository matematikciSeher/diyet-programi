import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';

/// Aktivite kaydının kaynağı.
///
/// [health] platform toplamıdır; aynı günün manuel adımları bunun üzerine
/// eklenmez.
enum ActivitySource { local, manual, health }

/// Bir güne ait hareket özeti (ActivityLog).
class DailyActivity extends Equatable {
  const DailyActivity({
    this.steps = 0,
    this.activeCalories = 0,
    this.exerciseMinutes = 0,
    this.distanceMeters,
    this.workoutCount,
    this.source = ActivitySource.local,
    this.lastSyncedAt,
    this.stepsKnown = true,
    this.caloriesKnown = true,
    this.distanceKnown = false,
    this.workoutsKnown = false,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
    steps: JsonUtils.readInt(json['steps']),
    activeCalories: JsonUtils.readDouble(json['activeCalories']),
    exerciseMinutes: JsonUtils.readInt(json['exerciseMinutes']),
    distanceMeters: JsonUtils.readDoubleOrNull(json['distanceMeters']),
    workoutCount: JsonUtils.readIntOrNull(json['workoutCount']),
    source: JsonUtils.readEnum(
      ActivitySource.values,
      json['source'],
      ActivitySource.local,
    ),
    lastSyncedAt: JsonUtils.readDate(json['lastSyncedAt']),
    stepsKnown: json.containsKey('stepsKnown')
        ? json['stepsKnown'] == true
        : true,
    caloriesKnown: json.containsKey('caloriesKnown')
        ? json['caloriesKnown'] == true
        : true,
    distanceKnown: json.containsKey('distanceKnown')
        ? json['distanceKnown'] == true
        : json['distanceMeters'] != null,
    workoutsKnown: json.containsKey('workoutsKnown')
        ? json['workoutsKnown'] == true
        : json['workoutCount'] != null,
  );

  static const empty = DailyActivity();

  final int steps;

  /// Dinlenme metabolizması dışında harcanan enerji (kcal).
  final double activeCalories;
  final int exerciseMinutes;

  /// Metre. Platform desteklemiyorsa `null` ve [distanceKnown] false.
  final double? distanceMeters;
  final int? workoutCount;
  final ActivitySource source;
  final DateTime? lastSyncedAt;

  /// `false` ise sayı yok sayılır; 0 gerçek ölçüm değildir.
  final bool stepsKnown;
  final bool caloriesKnown;
  final bool distanceKnown;
  final bool workoutsKnown;

  bool get isEmpty =>
      steps == 0 &&
      activeCalories == 0 &&
      exerciseMinutes == 0 &&
      (distanceMeters == null || distanceMeters == 0);

  bool sameMeasurement(DailyActivity other) =>
      steps == other.steps &&
      activeCalories == other.activeCalories &&
      exerciseMinutes == other.exerciseMinutes &&
      distanceMeters == other.distanceMeters &&
      workoutCount == other.workoutCount &&
      stepsKnown == other.stepsKnown &&
      caloriesKnown == other.caloriesKnown &&
      distanceKnown == other.distanceKnown &&
      workoutsKnown == other.workoutsKnown;

  DailyActivity copyWith({
    int? steps,
    double? activeCalories,
    int? exerciseMinutes,
    double? distanceMeters,
    int? workoutCount,
    ActivitySource? source,
    DateTime? lastSyncedAt,
    bool? stepsKnown,
    bool? caloriesKnown,
    bool? distanceKnown,
    bool? workoutsKnown,
  }) => DailyActivity(
    steps: steps ?? this.steps,
    activeCalories: activeCalories ?? this.activeCalories,
    exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    workoutCount: workoutCount ?? this.workoutCount,
    source: source ?? this.source,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    stepsKnown: stepsKnown ?? this.stepsKnown,
    caloriesKnown: caloriesKnown ?? this.caloriesKnown,
    distanceKnown: distanceKnown ?? this.distanceKnown,
    workoutsKnown: workoutsKnown ?? this.workoutsKnown,
  );

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'activeCalories': activeCalories,
    'exerciseMinutes': exerciseMinutes,
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
    if (workoutCount != null) 'workoutCount': workoutCount,
    'source': source.name,
    if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt!.toIso8601String(),
    'stepsKnown': stepsKnown,
    'caloriesKnown': caloriesKnown,
    'distanceKnown': distanceKnown,
    'workoutsKnown': workoutsKnown,
  };

  @override
  List<Object?> get props => [
    steps,
    activeCalories,
    exerciseMinutes,
    distanceMeters,
    workoutCount,
    source,
    lastSyncedAt,
    stepsKnown,
    caloriesKnown,
    distanceKnown,
    workoutsKnown,
  ];
}

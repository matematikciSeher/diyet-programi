import 'package:equatable/equatable.dart';

enum HealthDataType {
  steps,
  activeEnergy,
  distance,
  workout,
  weight,
  water,
  sleep,
  heartRate,
}

/// İlk aşamada okunan hareket türleri. Yazma izni istenmez.
const healthActivityReadTypes = {
  HealthDataType.steps,
  HealthDataType.activeEnergy,
  HealthDataType.distance,
  HealthDataType.workout,
};

class HealthSample extends Equatable {
  const HealthSample({
    required this.type,
    required this.value,
    required this.from,
    required this.to,
    this.sourceName,
  });

  final HealthDataType type;
  final double value;
  final DateTime from;
  final DateTime to;
  final String? sourceName;

  @override
  List<Object?> get props => [type, value, from, to, sourceName];
}

class HealthWorkout extends Equatable {
  const HealthWorkout({
    required this.from,
    required this.to,
    this.activityType,
    this.activeCalories,
    this.distanceMeters,
    this.steps,
  });

  final DateTime from;
  final DateTime to;
  final String? activityType;
  final double? activeCalories;
  final double? distanceMeters;

  /// Antrenman içindeki adım. Günlük adıma eklenmez; platform toplamı yeter.
  final int? steps;

  int get durationMinutes {
    final minutes = to.difference(from).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  @override
  List<Object?> get props => [
    from,
    to,
    activityType,
    activeCalories,
    distanceMeters,
    steps,
  ];
}

/// Apple Health (iOS) ve Health Connect (Android) soyutlaması.
///
/// Desteklenmeyen ölçüm `null` döner. Sahte sayı üretilmez.
/// [write] ilk aşamada her zaman reddedilir.
abstract interface class HealthDataService {
  Future<bool> isAvailable();

  /// `true` izin var, `false` yok, `null` platform söylemiyor (iOS okuma).
  Future<bool?> hasPermissions(Set<HealthDataType> read);

  Future<bool> requestPermissions(
    Set<HealthDataType> read, {
    Set<HealthDataType> write = const {},
  });

  Future<List<HealthSample>> read(
    HealthDataType type, {
    required DateTime from,
    required DateTime to,
  });

  Future<int?> getSteps({required DateTime from, required DateTime to});

  Future<double?> getActiveCalories({
    required DateTime from,
    required DateTime to,
  });

  Future<double?> getDistanceMeters({
    required DateTime from,
    required DateTime to,
  });

  /// `null`: tür bu platformda yok veya okunamadı. Boş liste: kayıt yok.
  Future<List<HealthWorkout>?> getWorkouts({
    required DateTime from,
    required DateTime to,
  });

  Future<bool> write(HealthSample sample);
}

class UnavailableHealthDataService implements HealthDataService {
  const UnavailableHealthDataService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool?> hasPermissions(Set<HealthDataType> read) async => false;

  @override
  Future<bool> requestPermissions(
    Set<HealthDataType> read, {
    Set<HealthDataType> write = const {},
  }) async => false;

  @override
  Future<List<HealthSample>> read(
    HealthDataType type, {
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<int?> getSteps({required DateTime from, required DateTime to}) async =>
      null;

  @override
  Future<double?> getActiveCalories({
    required DateTime from,
    required DateTime to,
  }) async => null;

  @override
  Future<double?> getDistanceMeters({
    required DateTime from,
    required DateTime to,
  }) async => null;

  @override
  Future<List<HealthWorkout>?> getWorkouts({
    required DateTime from,
    required DateTime to,
  }) async => null;

  @override
  Future<bool> write(HealthSample sample) async => false;
}

import 'package:flutter/foundation.dart';

import 'health_data_service.dart';

enum FakeHealthPermission { granted, denied, undetermined }

/// Yalnızca test. Release kurucusu hata fırlatır; sağlayıcı bunu seçmez.
final class FakeHealthDataService implements HealthDataService {
  FakeHealthDataService({
    this.available = true,
    this.permission = FakeHealthPermission.granted,
    this.steps = 6000,
    this.activeCalories = 500,
    this.distanceMeters = 4200,
    this.workouts = const [],
    bool? isRelease,
  }) {
    if (isRelease ?? kReleaseMode) {
      throw StateError(
        'FakeHealthDataService is test-only and must not run in release.',
      );
    }
  }

  bool available;
  FakeHealthPermission permission;
  int? steps;
  double? activeCalories;
  double? distanceMeters;
  List<HealthWorkout>? workouts;
  bool throwOnRead = false;

  int stepsReads = 0;
  int calorieReads = 0;
  int distanceReads = 0;
  int workoutReads = 0;
  int permissionRequests = 0;
  DateTime? lastFrom;
  DateTime? lastTo;

  void _touch(DateTime from, DateTime to) {
    lastFrom = from;
    lastTo = to;
    if (throwOnRead) throw StateError('health read failed');
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool?> hasPermissions(Set<HealthDataType> read) async {
    if (!available) return false;
    return switch (permission) {
      FakeHealthPermission.granted => true,
      FakeHealthPermission.denied => false,
      FakeHealthPermission.undetermined => null,
    };
  }

  @override
  Future<bool> requestPermissions(
    Set<HealthDataType> read, {
    Set<HealthDataType> write = const {},
  }) async {
    permissionRequests++;
    if (!available || permission == FakeHealthPermission.denied) return false;
    permission = FakeHealthPermission.granted;
    return true;
  }

  @override
  Future<List<HealthSample>> read(
    HealthDataType type, {
    required DateTime from,
    required DateTime to,
  }) async {
    final value = switch (type) {
      HealthDataType.steps => (await getSteps(from: from, to: to))?.toDouble(),
      HealthDataType.activeEnergy => await getActiveCalories(
        from: from,
        to: to,
      ),
      HealthDataType.distance => await getDistanceMeters(from: from, to: to),
      _ => null,
    };
    if (value == null) return const [];
    return [
      HealthSample(type: type, value: value, from: from, to: to),
    ];
  }

  @override
  Future<int?> getSteps({required DateTime from, required DateTime to}) async {
    stepsReads++;
    _touch(from, to);
    if (!available || permission == FakeHealthPermission.denied) return null;
    return steps;
  }

  @override
  Future<double?> getActiveCalories({
    required DateTime from,
    required DateTime to,
  }) async {
    calorieReads++;
    _touch(from, to);
    if (!available || permission == FakeHealthPermission.denied) return null;
    return activeCalories;
  }

  @override
  Future<double?> getDistanceMeters({
    required DateTime from,
    required DateTime to,
  }) async {
    distanceReads++;
    _touch(from, to);
    if (!available || permission == FakeHealthPermission.denied) return null;
    return distanceMeters;
  }

  @override
  Future<List<HealthWorkout>?> getWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    workoutReads++;
    _touch(from, to);
    if (!available || permission == FakeHealthPermission.denied) return null;
    return workouts;
  }

  @override
  Future<bool> write(HealthSample sample) async => false;
}

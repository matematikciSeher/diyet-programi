import 'dart:io';

import 'package:health/health.dart' as hc;
import 'package:permission_handler/permission_handler.dart';

import 'health_data_service.dart';
import 'health_platform_support.dart';

/// Health Connect ve HealthKit okuma adaptörü.
///
/// Yazma izni istenmez ve [write] platforma gitmez.
final class PlatformHealthDataService implements HealthDataService {
  PlatformHealthDataService({hc.Health? health}) : _health = health ?? hc.Health();

  final hc.Health _health;
  bool _configured = false;

  Future<bool> _ready() async {
    if (!healthPlatformSupported) return false;
    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }
      if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
        return false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  hc.HealthDataType? _pluginType(HealthDataType type) {
    final mapped = switch (type) {
      HealthDataType.steps => hc.HealthDataType.STEPS,
      HealthDataType.activeEnergy => hc.HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.distance => Platform.isIOS
          ? hc.HealthDataType.DISTANCE_WALKING_RUNNING
          : hc.HealthDataType.DISTANCE_DELTA,
      HealthDataType.workout => hc.HealthDataType.WORKOUT,
      HealthDataType.weight ||
      HealthDataType.water ||
      HealthDataType.sleep ||
      HealthDataType.heartRate => null,
    };
    if (mapped == null || !_health.isDataTypeAvailable(mapped)) return null;
    return mapped;
  }

  List<hc.HealthDataType> _available(Set<HealthDataType> types) => [
    for (final type in types) ?_pluginType(type),
  ];

  @override
  Future<bool> isAvailable() => _ready();

  @override
  Future<bool?> hasPermissions(Set<HealthDataType> read) async {
    if (!await _ready()) return false;
    final types = _available(read);
    if (types.isEmpty) return false;
    try {
      return await _health.hasPermissions(types);
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> requestPermissions(
    Set<HealthDataType> read, {
    Set<HealthDataType> write = const {},
  }) async {
    if (!await _ready()) return false;
    final types = _available(read);
    if (types.isEmpty) return false;
    try {
      if (Platform.isAndroid) {
        await Permission.activityRecognition.request();
      }
      return await _health.requestAuthorization(
        types,
        permissions: [for (final _ in types) hc.HealthDataAccess.READ],
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<int?> getSteps({required DateTime from, required DateTime to}) async {
    if (!await _ready() || _pluginType(HealthDataType.steps) == null) {
      return null;
    }
    try {
      if (await _health.hasPermissions([hc.HealthDataType.STEPS]) == false) {
        return null;
      }
      return await _health.getTotalStepsInInterval(from, to);
    } on Object {
      return null;
    }
  }

  @override
  Future<double?> getActiveCalories({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _points(
      HealthDataType.activeEnergy,
      from: from,
      to: to,
      unit: hc.HealthDataUnit.KILOCALORIE,
    );
    if (points == null) return null;
    return points.fold<double>(0, (sum, point) => sum + _kcal(point));
  }

  @override
  Future<double?> getDistanceMeters({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _points(
      HealthDataType.distance,
      from: from,
      to: to,
      unit: hc.HealthDataUnit.METER,
    );
    if (points == null) return null;
    return points.fold<double>(0, (sum, point) => sum + _meters(point));
  }

  @override
  Future<List<HealthWorkout>?> getWorkouts({
    required DateTime from,
    required DateTime to,
  }) async {
    final points = await _points(HealthDataType.workout, from: from, to: to);
    if (points == null) return null;
    return [
      for (final point in points)
        if (point.value is hc.WorkoutHealthValue)
          HealthWorkout(
            from: point.dateFrom,
            to: point.dateTo,
            activityType: (point.value as hc.WorkoutHealthValue)
                .workoutActivityType
                .name,
            activeCalories: _optionalKcal(point),
            distanceMeters: _optionalMeters(point),
            steps: (point.value as hc.WorkoutHealthValue).totalSteps,
          ),
    ];
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
    return [HealthSample(type: type, value: value, from: from, to: to)];
  }

  @override
  Future<bool> write(HealthSample sample) async => false;

  Future<List<hc.HealthDataPoint>?> _points(
    HealthDataType type, {
    required DateTime from,
    required DateTime to,
    hc.HealthDataUnit? unit,
  }) async {
    if (!await _ready()) return null;
    final pluginType = _pluginType(type);
    if (pluginType == null) return null;
    try {
      if (await _health.hasPermissions([pluginType]) == false) return null;
      return await _health.getHealthDataFromTypes(
        types: [pluginType],
        startTime: from,
        endTime: to,
        preferredUnits: unit == null ? null : {pluginType: unit},
      );
    } on Object {
      return null;
    }
  }

  double _kcal(hc.HealthDataPoint point) {
    final value = point.value;
    if (value is! hc.NumericHealthValue) return 0;
    final number = value.numericValue.toDouble();
    return switch (point.unit) {
      hc.HealthDataUnit.KILOCALORIE || hc.HealthDataUnit.LARGE_CALORIE => number,
      hc.HealthDataUnit.SMALL_CALORIE => number / 1000,
      hc.HealthDataUnit.JOULE => number / 4184,
      _ => number,
    };
  }

  double? _optionalKcal(hc.HealthDataPoint point) {
    final value = point.value;
    if (value is! hc.WorkoutHealthValue) return null;
    final burned = value.totalEnergyBurned;
    if (burned == null) return null;
    return burned.toDouble();
  }

  double _meters(hc.HealthDataPoint point) {
    final value = point.value;
    if (value is! hc.NumericHealthValue) return 0;
    return value.numericValue.toDouble();
  }

  double? _optionalMeters(hc.HealthDataPoint point) {
    final value = point.value;
    if (value is! hc.WorkoutHealthValue || value.totalDistance == null) {
      return null;
    }
    return value.totalDistance!.toDouble();
  }
}

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/body_measurement.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/data/datasources/demo_day_seeder.dart';
import '../../../measurements/data/repositories/measurement_repository_impl.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../../weight/data/repositories/weight_repository_impl.dart';

/// `useFakeServices` açıkken ilerleme ekranı boş görünmesin diye geçmiş
/// kilo, ölçü, öğün ve su kayıtları ekler. Kullanıcı başına bir kez,
/// yalnızca hiç kilo ve ölçü kaydı yokken çalışır.
final demoHistorySeederProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || !ref.watch(appConfigProvider).useFakeServices) return;
  await ref.watch(demoDaySeederProvider.future);

  final weights = ref.read(weightRepositoryProvider);
  final measurements = ref.read(measurementRepositoryProvider);
  if ((await weights.watchEntries(limit: 1).first).isNotEmpty ||
      (await measurements.watchMeasurements().first).isNotEmpty) {
    return;
  }

  final now = ref.read(clockProvider)();
  final today = now.startOfDay;
  DateTime daysAgo(int n, [int hour = 8]) =>
      DateTime(today.year, today.month, today.day - n, hour);

  final profile = await ref.read(userProfileProvider.future);
  final currentKg = profile?.weight ?? 78;
  final startKg =
      profile?.targetWeight != null && profile!.targetWeight! > currentKg
      ? currentKg - _weightSpanKg
      : currentKg + _weightSpanKg;

  for (var n = _historyDays; n >= 0; n -= 3) {
    final t = 1 - n / _historyDays;
    final wobble = math.sin(n * 1.7) * 0.25;
    final kg = startKg + (currentKg - startKg) * t + (n == 0 ? 0 : wobble);
    await weights.addEntry(
      weightKg: double.parse(kg.toStringAsFixed(1)),
      recordedAt: daysAgo(n, 7),
    );
  }

  final loss = startKg > currentKg ? 1 : -1;
  for (var n = _historyDays; n >= 0; n -= 28) {
    final t = 1 - n / _historyDays;
    double cm(double start, double delta) =>
        double.parse((start - delta * t * loss).toStringAsFixed(1));
    await measurements.addMeasurement(
      BodyMeasurement(
        id: '',
        recordedAt: daysAgo(n, 7),
        waistCm: cm(94, 5),
        hipCm: cm(104, 3.5),
        chestCm: cm(100, 3),
        armCm: cm(32, 1.2),
        thighCm: cm(58, 2),
        bodyFatPercent: cm(28, 2.5),
      ),
    );
  }

  final meals = ref.read(mealLogRepositoryProvider);
  final water = ref.read(waterRepositoryProvider);
  for (var n = 1; n <= _loggedDays; n++) {
    // Arada kayıt girilmemiş günler de olsun.
    if (n % 9 == 0) continue;
    final day = daysAgo(n, 0);
    final dayMeals = demoMealsFor(day);
    final skip = n % dayMeals.length;
    for (final (i, entry) in dayMeals.indexed) {
      if (i == skip) continue;
      if (n.isEven && entry.tags.contains(FoodTag.processed)) continue;
      await meals.addEntry(entry);
    }
    await meals.addEntry(_dinner(day, n));
    final glasses = 6 + (n * 5) % 6;
    for (var g = 0; g < glasses; g++) {
      await water.addWater(250, at: daysAgo(n, 8 + g));
    }
  }
});

const _historyDays = 84;
const _loggedDays = 30;
const _weightSpanKg = 4.2;

MealEntry _dinner(DateTime day, int variant) {
  final (name, grams, serving, nutrition) = switch (variant % 3) {
    0 => (
      'Fırında somon ve bulgur pilavı',
      320.0,
      '1 tabak',
      const NutritionFacts(
        calories: 520,
        proteinG: 38,
        carbsG: 45,
        fatG: 20,
        fiberG: 6,
      ),
    ),
    1 => (
      'Zeytinyağlı taze fasulye ve yoğurt',
      350.0,
      '1 tabak',
      const NutritionFacts(
        calories: 330,
        proteinG: 14,
        carbsG: 30,
        fatG: 17,
        fiberG: 8,
      ),
    ),
    _ => (
      'Köfte, pilav ve salata',
      380.0,
      '1 porsiyon',
      const NutritionFacts(
        calories: 690,
        proteinG: 34,
        carbsG: 62,
        fatG: 32,
        fiberG: 4,
      ),
    ),
  };
  return MealEntry(
    id: '',
    dayKey: day.dayKey,
    mealType: MealType.dinner,
    name: name,
    quantityGrams: grams,
    servingLabel: serving,
    nutrition: nutrition,
    loggedAt: day.add(const Duration(hours: 19, minutes: 30)),
    tags: variant % 3 == 1 ? const {FoodTag.vegetable} : const {},
  );
}

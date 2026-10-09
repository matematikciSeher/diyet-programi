import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/models/nutrition_facts.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../../water/data/repositories/water_repository_impl.dart';

/// `useFakeServices` açıkken bugünün günlüğü boşsa örnek öğün ve su
/// kayıtlarını repository'ler üzerinden ekler. Kullanıcı başına bir kez
/// çalışır; gerçek backend bağlandığında devre dışı kalır.
final demoDaySeederProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null || !ref.watch(appConfigProvider).useFakeServices) return;

  final now = ref.read(clockProvider)();
  final meals = ref.read(mealLogRepositoryProvider);
  final water = ref.read(waterRepositoryProvider);

  if ((await meals.watchDay(now).first).isEmpty) {
    for (final entry in demoMealsFor(now)) {
      await meals.addEntry(entry);
    }
  }
  if ((await water.watchDay(now).first).isEmpty) {
    final start = now.startOfDay.add(const Duration(hours: 8));
    for (var i = 0; i < 5; i++) {
      await water.addWater(250, at: start.add(Duration(hours: i * 2)));
    }
  }
});

/// Örnek bir günün öğünleri; [now] gününe tarihlenir.
List<MealEntry> demoMealsFor(DateTime now) {
  final day = now.startOfDay;
  MealEntry entry(
    MealType type,
    Duration time,
    String name,
    double grams,
    String serving,
    NutritionFacts nutrition, [
    Set<FoodTag> tags = const {},
  ]) => MealEntry(
    id: '',
    dayKey: day.dayKey,
    mealType: type,
    name: name,
    quantityGrams: grams,
    servingLabel: serving,
    nutrition: nutrition,
    loggedAt: day.add(time),
    tags: tags,
  );

  const breakfast = Duration(hours: 8, minutes: 15);
  const lunch = Duration(hours: 12, minutes: 45);
  const snack = Duration(hours: 16);
  return [
    entry(
      MealType.breakfast,
      breakfast,
      'Haşlanmış yumurta',
      100,
      '2 adet',
      const NutritionFacts(calories: 155, proteinG: 13, carbsG: 1, fatG: 11),
    ),
    entry(
      MealType.breakfast,
      breakfast,
      'Tam buğday ekmeği',
      60,
      '2 dilim',
      const NutritionFacts(
        calories: 150,
        proteinG: 7,
        carbsG: 25,
        fatG: 2,
        fiberG: 4,
      ),
      {FoodTag.wholeGrain},
    ),
    entry(
      MealType.breakfast,
      breakfast,
      'Beyaz peynir',
      40,
      '1 dilim',
      const NutritionFacts(calories: 105, proteinG: 7, carbsG: 1, fatG: 8),
    ),
    entry(
      MealType.breakfast,
      breakfast,
      'Domates ve salatalık',
      150,
      '1 tabak',
      const NutritionFacts(
        calories: 30,
        proteinG: 1.5,
        carbsG: 6,
        fatG: 0.3,
        fiberG: 2,
      ),
      {FoodTag.vegetable},
    ),
    entry(
      MealType.lunch,
      lunch,
      'Mercimek çorbası',
      250,
      '1 kase',
      const NutritionFacts(
        calories: 180,
        proteinG: 11,
        carbsG: 28,
        fatG: 3,
        fiberG: 7,
      ),
    ),
    entry(
      MealType.lunch,
      lunch,
      'Izgara tavuk göğsü',
      120,
      '1 porsiyon',
      const NutritionFacts(calories: 198, proteinG: 37, carbsG: 0, fatG: 4.3),
    ),
    entry(
      MealType.lunch,
      lunch,
      'Çoban salata',
      150,
      '1 kase',
      const NutritionFacts(
        calories: 60,
        proteinG: 1.5,
        carbsG: 8,
        fatG: 3,
        fiberG: 3,
      ),
      {FoodTag.vegetable},
    ),
    entry(
      MealType.lunch,
      lunch,
      'Ayran',
      200,
      '1 bardak',
      const NutritionFacts(calories: 76, proteinG: 3.4, carbsG: 5, fatG: 4),
    ),
    entry(
      MealType.snack,
      snack,
      'Elma',
      180,
      '1 orta boy',
      const NutritionFacts(
        calories: 94,
        proteinG: 0.5,
        carbsG: 25,
        fatG: 0.3,
        fiberG: 4.3,
      ),
      {FoodTag.fruit},
    ),
    entry(
      MealType.snack,
      snack,
      'Çikolatalı gofret',
      36,
      '1 adet',
      const NutritionFacts(
        calories: 197,
        proteinG: 2.5,
        carbsG: 22,
        fatG: 11,
        sugarG: 14,
      ),
      {FoodTag.processed},
    ),
  ];
}

import 'package:diyet_programi/features/meals/domain/models/daily_log.dart';
import 'package:diyet_programi/features/meals/presentation/providers/diary_providers.dart';
import 'package:diyet_programi/features/progress/data/datasources/demo_history_seeder.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final testNow = DateTime(2026, 9, 28, 14, 30);

MealEntry entry(
  MealType type, {
  String id = '',
  String name = 'Yiyecek',
  double kcal = 100,
  double protein = 0,
  double carbs = 0,
  double fat = 0,
  double grams = 100,
  DateTime? at,
}) {
  final loggedAt = at ?? testNow;
  return MealEntry(
    id: id,
    dayKey: '',
    mealType: type,
    name: name,
    quantityGrams: grams,
    quantity: grams,
    unit: PortionUnit.gram,
    nutrition: NutritionFacts(
      calories: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    ),
    loggedAt: loggedAt,
  );
}

/// Oturum açık, demo verisi olmayan, saati sabit bir container.
ProviderContainer diaryContainer() {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => testNow),
      currentUserIdProvider.overrideWithValue('user-1'),
      keyValueStorageProvider.overrideWithValue(InMemoryKeyValueStorage()),
      demoHistorySeederProvider.overrideWith((ref) async {}),
    ],
  );
  container.listen(dailyLogProvider, (_, _) {});
  return container;
}

/// Stream'lerin güncel değeri yayınlamasını bekler.
Future<DailyLog> settledLog(ProviderContainer container) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(dailyLogProvider).requireValue;
}

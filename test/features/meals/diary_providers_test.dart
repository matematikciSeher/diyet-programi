import 'package:diyet_programi/core/utils/extensions/date_extensions.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/domain/usecases/diary_actions.dart';
import 'package:diyet_programi/features/meals/presentation/providers/diary_providers.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'diary_test_utils.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = diaryContainer());
  tearDown(() => container.dispose());

  DiaryActions actions() => container.read(diaryActionsProvider);

  Future<MealEntry> add(MealEntry e) async =>
      (await container.read(mealLogRepositoryProvider).addEntry(e))
          .valueOrNull!;

  group('selectedDateProvider', () {
    test('varsayılan olarak bugündür', () {
      expect(container.read(selectedDateProvider), testNow.startOfDay);
    });

    test('ileri tarih sınırı aşılamaz', () {
      final controller = container.read(selectedDateProvider.notifier);
      controller.select(testNow.addDays(100));
      expect(
        container.read(selectedDateProvider),
        DiaryDateRange.last(testNow),
      );
      expect(controller.canGoForward, isFalse);
      controller.goToToday();
      expect(container.read(selectedDateProvider), testNow.startOfDay);
    });
  });

  test('tarih değişince o günün kaydı gelir', () async {
    final yesterday = testNow.addDays(-1);
    await add(entry(MealType.lunch, name: 'Bugün', kcal: 500));
    await add(entry(MealType.dinner, name: 'Dün', kcal: 700, at: yesterday));

    var log = await settledLog(container);
    expect(log.date, testNow.startOfDay);
    expect(log.entries.map((e) => e.name), ['Bugün']);

    container.read(selectedDateProvider.notifier).previous();
    log = await settledLog(container);
    expect(log.date, yesterday.startOfDay);
    expect(log.entries.map((e) => e.name), ['Dün']);
    expect(log.totals.calories, 700);
  });

  test('yemek eklenince toplamlar ve skor güncellenir', () async {
    var log = await settledLog(container);
    expect(log.isEmpty, isTrue);
    expect(container.read(nutritionScoreProvider)!.value, 0);

    await add(entry(MealType.breakfast, kcal: 400, protein: 30));
    log = await settledLog(container);
    expect(container.read(dailyNutritionTotalsProvider)!.calories, 400);
    expect(
      container.read(mealLogProvider(MealType.breakfast))!.entries,
      hasLength(1),
    );
    expect(container.read(nutritionScoreProvider)!.value, greaterThan(0));
    expect(log.isEmpty, isFalse);
  });

  test('silme toplamları günceller', () async {
    final a = await add(entry(MealType.lunch, kcal: 300));
    await add(entry(MealType.lunch, kcal: 200));
    expect((await settledLog(container)).totals.calories, 500);

    await actions().deleteEntry(a);
    final log = await settledLog(container);
    expect(log.totals.calories, 200);
    expect(log.meal(MealType.lunch).entries, hasLength(1));

    await actions().restoreEntry(a);
    expect((await settledLog(container)).totals.calories, 500);
  });

  test('taşıma eski ve yeni öğünü günceller, gün toplamı değişmez', () async {
    final a = await add(entry(MealType.breakfast, kcal: 300));
    await add(entry(MealType.breakfast, kcal: 100));
    await settledLog(container);

    await actions().moveEntry(a, MealType.dinner);
    final log = await settledLog(container);
    expect(log.meal(MealType.breakfast).total.calories, 100);
    expect(log.meal(MealType.dinner).total.calories, 300);
    expect(log.totals.calories, 400);
  });

  test('düzenleme miktarı ve besin değerlerini ölçekler', () async {
    final a = await add(entry(MealType.lunch, kcal: 200, protein: 10));
    await actions().updateEntry(a, factor: 1.5, mealType: MealType.snack);
    final log = await settledLog(container);
    final updated = log.meal(MealType.snack).entries.single;
    expect(updated.calories, 300);
    expect(updated.protein, 15);
    expect(updated.quantityGrams, 150);
    expect(updated.updatedAt, testNow);
    expect(log.meal(MealType.lunch).isEmpty, isTrue);
  });

  test('kopyalama seçilen güne yeni kayıt ekler', () async {
    final a = await add(entry(MealType.lunch, kcal: 250));
    final tomorrow = testNow.addDays(1);
    await actions().copyEntry(a, tomorrow);

    expect((await settledLog(container)).totals.calories, 250);
    container.read(selectedDateProvider.notifier).next();
    final log = await settledLog(container);
    expect(log.meal(MealType.lunch).entries.single.calories, 250);
  });

  test('su ekleme ve azaltma ilerlemeyi günceller', () async {
    await settledLog(container);
    await actions().addWater(250, testNow);
    await actions().addWater(500, testNow);
    await settledLog(container);
    var water = container.read(waterProgressProvider)!;
    expect(water.consumedMl, 750);
    expect(water.goalMl, greaterThan(0));

    await actions().removeWater(250, water.logs);
    await settledLog(container);
    water = container.read(waterProgressProvider)!;
    expect(water.consumedMl, 500);

    await actions().removeWater(1000, water.logs);
    await settledLog(container);
    expect(container.read(waterProgressProvider)!.consumedMl, 0);
  });

  test('geçmiş güne eklenen su o güne kaydedilir', () async {
    final past = testNow.addDays(-3);
    container.read(selectedDateProvider.notifier).select(past);
    await settledLog(container);
    await actions().addWater(250, past);
    expect((await settledLog(container)).waterAmount, 250);

    container.read(selectedDateProvider.notifier).goToToday();
    expect((await settledLog(container)).waterAmount, 0);
  });

  test('kilo seçili güne kaydedilir', () async {
    final past = testNow.addDays(-2);
    container.read(selectedDateProvider.notifier).select(past);
    await settledLog(container);
    await actions().addWeight(72.4, actions().timestampFor(past));
    await settledLog(container);
    expect(container.read(diaryWeightProvider), 72.4);
  });
}

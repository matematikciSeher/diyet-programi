import 'package:diyet_programi/features/ai_coach/data/repositories/assistant_context_repository_impl.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_safety.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/mock_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/fasting/data/repositories/fasting_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/data/datasources/meal_template_catalog.dart';
import 'package:diyet_programi/features/meal_plans/data/repositories/meal_plan_repository_impl.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/meal_plan_generator.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:diyet_programi/features/progress/data/repositories/body_progress_repository_impl.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/repositories/local_user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late LocalUserProfileRepository profiles;
  late MealLogRepositoryImpl meals;
  late WaterRepositoryImpl water;
  late RepositoryAssistantContextRepository contextRepo;
  late MockNutritionAssistantService assistant;

  setUp(() async {
    db = InMemoryDocumentDatabase();
    profiles = LocalUserProfileRepository(InMemoryKeyValueStorage());
    meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
    water = WaterRepositoryImpl(db, 'user-1');
    contextRepo = RepositoryAssistantContextRepository(
      profiles: profiles,
      meals: meals,
      water: water,
      body: CombinedBodyProgressRepository(
        weights: WeightRepositoryImpl(db, 'user-1'),
        measurements: MeasurementRepositoryImpl(db, 'user-1'),
      ),
      plans: MealPlanRepositoryImpl(db, 'user-1'),
      fasting: FastingRepositoryImpl(db, 'user-1'),
      clock: () => testNow,
    );
    assistant = MockNutritionAssistantService(
      MealPlanGenerator(MealTemplateCatalog.all),
    );
    await profiles.saveProfile(testProfile());
  });

  tearDown(() {
    db.dispose();
    profiles.dispose();
  });

  test('asistan günlük kalori ve su kaydını okur', () async {
    await meals.addEntry(
      MealEntry(
        id: '',
        dayKey: '',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(
          calories: 520,
          proteinG: 45,
          carbsG: 10,
          fatG: 18,
        ),
        loggedAt: testNow,
      ),
    );
    await water.addWater(750, at: testNow);

    final context = await contextRepo.snapshot();
    expect(context.consumed.calories, 520);
    expect(context.todayWaterMl, 750);
    expect(context.remainingCalories, 1850 - 520);
    expect(context.profile?.id, 'user-1');

    final calories = await assistant.reply('Bugün kaç kalori hakkım kaldı?', context);
    expect(
      calories,
      isA<RemainingCaloriesReply>()
          .having((r) => r.consumed, 'consumed', 520)
          .having((r) => r.target, 'target', 1850)
          .having((r) => r.remaining, 'remaining', 1330),
    );

    final protein = await assistant.reply('Bugün protein hedefime ulaştım mı?', context);
    expect(
      protein,
      isA<ProteinStatusReply>()
          .having((r) => r.consumed, 'consumed', 45)
          .having((r) => r.reached, 'reached', false),
    );

    final waterReply = await assistant.reply('Bugün ne kadar su içtim?', context);
    expect(
      waterReply,
      isA<WaterStatusReply>()
          .having((r) => r.consumedMl, 'consumedMl', 750)
          .having((r) => r.goalMl, 'goalMl', 2500),
    );
  });

  test('tıbbi ve tehlikeli sorular güvenli yanıta yönlendirilir', () async {
    final context = await contextRepo.snapshot();
    expect(
      await assistant.reply('Diyabet ilaçlarımı keseyim mi?', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('Haftada 5 kilo vermek istiyorum', context),
      const SafetyReply(SafetyConcern.extremeRestriction),
    );
    expect(
      AssistantSafety.check(
        MockNutritionAssistantService.normalize('kusmak istiyorum'),
      ),
      SafetyConcern.eatingDisorder,
    );
    expect(
      AssistantSafety.check(
        MockNutritionAssistantService.normalize('Bugün kaç kalori hakkım kaldı?'),
      ),
      isNull,
    );
    expect(
      await assistant.reply('Günde 800 kalori hedefle', context),
      const SafetyReply(SafetyConcern.extremeRestriction),
    );
    expect(
      await assistant.reply('gunde 800 kalori hedefle', context),
      const SafetyReply(SafetyConcern.extremeRestriction),
    );
    expect(
      await assistant.reply('Kahvaltida ne yesem? ac kalayim', context),
      const SafetyReply(SafetyConcern.extremeRestriction),
    );
    expect(
      await assistant.reply('hic yemesem', context),
      const SafetyReply(SafetyConcern.extremeRestriction),
    );
    expect(
      await assistant.reply('gogsum agriyor', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('nefesim daraliyor', context),
      const SafetyReply(SafetyConcern.emergency),
    );
    expect(
      await assistant.reply('ilacimin dozunu artir', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('50mg demir alayim mi', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply('tikinma ataklarim var', context),
      const SafetyReply(SafetyConcern.eatingDisorder),
    );
    expect(
      await assistant.reply('mushil kullanayim', context),
      const SafetyReply(SafetyConcern.eatingDisorder),
    );
    expect(
      await assistant.reply('kusacagim', context),
      const SafetyReply(SafetyConcern.eatingDisorder),
    );
    expect(
      await assistant.reply('kan sekerim yuksek, ne yiyeyim', context),
      const SafetyReply(SafetyConcern.medical),
    );
    expect(
      await assistant.reply(
        'Gebelik döneminde beslenme neden profesyonel takip gerektirir?',
        context,
      ),
      isA<GuideReply>().having(
        (reply) => reply.questionId,
        'id',
        'wom.pregnancy',
      ),
    );
  });

  test('kayıt yokken alım tahmini üretmez', () async {
    final context = await contextRepo.snapshot();
    expect(context.todayMeals, isEmpty);
    expect(
      await assistant.reply('Bugün nasıl besleniyorum?', context),
      isA<MissingRecordReply>().having(
        (reply) => reply.record,
        'record',
        MissingRecord.meals,
      ),
    );
    expect(
      await assistant.reply('Karbonhidratım nasıl?', context),
      isA<MissingRecordReply>(),
    );
    expect(
      await assistant.reply('Yağ kaydım ne durumda?', context),
      isA<MissingRecordReply>(),
    );
  });

  test('günlük kayıt protein karbonhidrat ve yağı değerlendirir', () async {
    await meals.addEntry(
      MealEntry(
        id: '',
        dayKey: '',
        mealType: MealType.lunch,
        name: 'Izgara tavuk',
        quantityGrams: 200,
        nutrition: const NutritionFacts(
          calories: 520,
          proteinG: 45,
          carbsG: 10,
          fatG: 18,
        ),
        loggedAt: testNow,
      ),
    );
    final context = await contextRepo.snapshot();
    final review = await assistant.reply('Bugün nasıl besleniyorum?', context);
    expect(review, isA<DailyNutritionReply>());
    final daily = review as DailyNutritionReply;
    expect(daily.mealCount, 1);
    expect(daily.consumedCalories, 520);
    expect(daily.macrosRecorded, isTrue);
    expect(daily.carbsConsumed, 10);
    expect(daily.fatConsumed, 18);
    expect(daily.targetBelowSafeFloor, isFalse);

    final carbs = await assistant.reply('Karbonhidrat durumum ne?', context);
    expect(
      carbs,
      isA<MacroStatusReply>()
          .having((reply) => reply.macro, 'macro', TrackedMacro.carbs)
          .having((reply) => reply.consumed, 'consumed', 10),
    );
  });
}

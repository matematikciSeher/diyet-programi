import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diyet_programi/core/config/app_config.dart';
import 'package:diyet_programi/core/config/app_environment.dart';
import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/api_client.dart';
import 'package:diyet_programi/features/activity/domain/models/daily_activity.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_context_builder.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_limits.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_service_selector.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/proxy_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/unconfigured_nutrition_assistant_service.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/models/recipe.dart';
import 'package:diyet_programi/shared/repositories/local_user_profile_repository.dart';
import 'package:diyet_programi/shared/services/ai/ai_nutrition_service.dart';
import 'package:diyet_programi/shared/services/ai/proxy_ai_nutrition_service.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  test('release sahte asistanı kapatır, örnek adres yapılandırma sayılmaz', () {
    expect(
      AppConfig.resolveUseFakeServices(
        requestedFakeServices: true,
        isRelease: true,
      ),
      isFalse,
    );
    final unconfigured = _config(useFakeServices: false, proxy: 'https://ai.example.com');
    expect(unconfigured.isAiProxyConfigured, isFalse);
    final selected = selectNutritionAssistantService(
      config: unconfigured,
      fake: const _FakeAssistant(),
      ai: const UnavailableAiNutritionService(),
      loadRecipes: (_) async => const [],
      loadWeek: (_) async => const [],
    );
    expect(selected, isA<UnconfiguredNutritionAssistantService>());
    expect(selected, isNot(isA<_FakeAssistant>()));
  });

  test('debug fake servisi yalnızca useFakeServices açıkken seçilir', () {
    const fake = _FakeAssistant();
    final selected = selectNutritionAssistantService(
      config: _config(useFakeServices: true, proxy: 'https://assistant.internal.test'),
      fake: fake,
      ai: const UnavailableAiNutritionService(),
      loadRecipes: (_) async => const [],
      loadWeek: (_) async => const [],
    );
    expect(identical(selected, fake), isTrue);

    final live = selectNutritionAssistantService(
      config: _config(useFakeServices: false, proxy: 'https://assistant.internal.test'),
      fake: fake,
      ai: const UnavailableAiNutritionService(),
      loadRecipes: (_) async => const [],
      loadWeek: (_) async => const [],
    );
    expect(live, isA<ProxyNutritionAssistantService>());
  });

  test('yapılandırılmamış asistan sahte övgü üretmez', () async {
    const service = UnconfiguredNutritionAssistantService();
    final reply = await service.reply(
      'Bugün nasıl besleniyorum?',
      _context(),
    );
    expect(reply, isA<UnavailableAssistantReply>());
    expect(
      (reply as UnavailableAssistantReply).code,
      AssistantErrorCodes.notConfigured,
    );
    expect(
      await service.reply('Diyabet ilaçlarımı keseyim mi?', _context()),
      isA<SafetyReply>(),
    );
  });

  test('boş mesaj istek yapmaz', () async {
    final ai = ScriptedAi((_) async => '{"text":"olmamalı","actions":[]}');
    final service = _proxy(ai);
    final reply = await service.reply('   ', _context());
    expect(reply, isA<AssistantFailureReply>());
    expect((reply as AssistantFailureReply).code, AssistantErrorCodes.emptyMessage);
    expect(ai.calls, 0);
  });

  test('zaman aşımı sınırlı tekrar eder ve sonsuza gitmez', () async {
    final ai = ScriptedAi((_) async {
      throw const NetworkException('timeout', code: 'timeout');
    });
    final service = _proxy(ai, limits: const AssistantLimits(maxRetries: 1));
    final reply = await service.reply('Bugün nasıl besleniyorum?', _context());
    expect((reply as AssistantFailureReply).code, AssistantErrorCodes.timeout);
    expect(ai.calls, 2);
  });

  test('ağ hatası sahte yanıt üretmez', () async {
    final ai = ScriptedAi((_) async {
      throw const NetworkException('no_connection', code: 'no_connection');
    });
    final reply = await _proxy(ai).reply('Bugün nasıl besleniyorum?', _context());
    expect((reply as AssistantFailureReply).code, AssistantErrorCodes.offline);
    expect(ai.calls, 1);
  });

  test('bozuk, geçersiz ve boş yanıt ayrılır', () async {
    final malformed = await _proxy(
      ScriptedAi((_) async => 'bu json değil'),
    ).reply('merhaba', _context());
    expect((malformed as AssistantFailureReply).code, AssistantErrorCodes.malformed);

    final invalid = await _proxy(
      ScriptedAi((_) async => '{"text":1,"actions":[]}'),
    ).reply('merhaba', _context());
    expect((invalid as AssistantFailureReply).code, AssistantErrorCodes.invalidResponse);

    final empty = await _proxy(
      ScriptedAi((_) async => '{"text":"","actions":[]}'),
    ).reply('merhaba', _context());
    expect((empty as AssistantFailureReply).code, AssistantErrorCodes.emptyResponse);
  });

  test('bağlam oluşturucu günlük kalori, su ve aktiviteyi kayıttan yazar', () {
    const builder = AssistantContextBuilder();
    final context = _context(
      meals: [
        _meal('Çorba', 300, protein: 12),
        _meal('Salata', 220, protein: 8),
      ],
      waterMl: 750,
      activity: const DailyActivity(
        steps: 4200,
        distanceMeters: 3100,
        activeCalories: 180,
        workoutCount: 1,
        stepsKnown: true,
        caloriesKnown: true,
        distanceKnown: true,
        workoutsKnown: true,
        source: ActivitySource.health,
      ),
    );

    final calories = builder.build(
      question: 'Bugün kaç kalori aldım?',
      context: context,
    );
    final nutrition = calories.payload['nutrition']! as Map;
    expect(nutrition['source'], 'daily_log');
    expect(nutrition['consumedKcal'], 520);
    expect(nutrition['targetKcal'], 1850);
    expect(nutrition['remainingKcal'], 1330);
    expect(calories.payload.containsKey('activity'), isFalse);
    expect(calories.payload.containsKey('profile'), isFalse);

    final water = builder.build(
      question: 'Bugün ne kadar su içtim?',
      context: context,
    );
    expect((water.payload['water']! as Map)['consumedMl'], 750);
    expect((water.payload['water']! as Map)['goalMl'], 2500);
    expect(water.payload.containsKey('activity'), isFalse);
    expect(water.payload.containsKey('profile'), isFalse);

    final activity = builder.build(
      question: 'Bugün kaç adım attım?',
      context: context,
    );
    final activityJson = activity.payload['activity']! as Map;
    expect(activityJson['deviceLocalOnly'], isTrue);
    expect(activityJson['steps'], 4200);
    expect(activityJson['distanceMeters'], 3100);
    expect(activityJson['activeKcal'], 180);
    expect(activityJson['workouts'], 1);
    expect(activity.payload.containsKey('profile'), isFalse);
  });

  test('öğün sorusu profili gönderir, katalogun tamamını göndermez', () {
    final recipes = [
      for (var i = 0; i < 12; i++) _recipe('r$i', 'Tarif $i'),
    ];
    final pack = const AssistantContextBuilder().build(
      question: 'Akşam ne yiyebilirim?',
      context: _context(),
      recipes: recipes,
    );
    final profile = pack.payload['profile']! as Map;
    expect(profile['goal'], 'loseWeight');
    expect(profile['dietType'], 'omnivore');
    expect(profile['allergies'], ['egg']);
    expect(profile.containsKey('name'), isFalse);
    final sent = pack.payload['recipeCandidates']! as List;
    expect(sent.length, 6);
    expect(pack.payload.containsKey('activity'), isFalse);
  });

  test('alerji, sevilmeyen yiyecek ve diyet adaylardan elenir', () async {
    final egg = _recipe(
      'egg-dish',
      'Omlet',
      ingredient: 'Yumurta',
      meal: MealType.dinner,
    );
    final disliked = _recipe(
      'broccoli',
      'Brokoli',
      ingredient: 'Brokoli',
      meal: MealType.dinner,
    );
    final chicken = _recipe(
      'chicken',
      'Tavuk',
      ingredient: 'Tavuk göğsü',
      meal: MealType.dinner,
    );
    final lentil = _recipe(
      'lentil',
      'Mercimek çorbası',
      ingredient: 'Mercimek',
      meal: MealType.dinner,
      calories: 280,
      protein: 18,
    );
    final ai = ScriptedAi((messages) async {
      final body = messages.last.content;
      expect(body.contains('egg-dish'), isFalse);
      expect(body.contains('broccoli'), isFalse);
      expect(body.contains('chicken'), isFalse);
      expect(body.contains('lentil'), isTrue);
      expect(body.contains('"name"'), isFalse);
      return '''
{"text":"Mercimek uygun.","actions":[
 {"type":"recommend_recipe","recipeId":"egg-dish"},
 {"type":"recommend_recipe","recipeId":"not-a-real-recipe"},
 {"type":"recommend_recipe","recipeId":"lentil"},
 {"type":"set_calories"}
]}
''';
    });
    final reply = await _proxy(
      ai,
      recipes: [egg, disliked, chicken, lentil],
    ).reply(
      'Akşam ne yiyebilirim?',
      _context(allergies: const ['egg'], disliked: const ['brokoli'], diet: DietType.vegan),
    );
    final interpreted = reply as InterpretedReply;
    expect(interpreted.recipes.map((r) => r.id), ['lentil']);
    expect(interpreted.recipes.single.title, 'Mercimek çorbası');
    expect(
      interpreted.actions.any((a) => a == AssistantAction.openRecipes),
      isTrue,
    );
  });

  test('uydurulan kalori yorumu kayıtın yerine geçmez ve veri yazılmaz', () async {
    final db = InMemoryDocumentDatabase();
    final profiles = LocalUserProfileRepository(InMemoryKeyValueStorage());
    final meals = MealLogRepositoryImpl(db, 'user-1', clock: () => testNow);
    addTearDown(() {
      db.dispose();
      profiles.dispose();
    });
    final profile = testProfile(allergies: const ['egg']);
    await profiles.saveProfile(profile);
    await meals.addEntry(_meal('Çorba', 520, protein: 20));
    final ai = ScriptedAi(
      (_) async =>
          '{"text":"Bugün 1500 kcal aldın, hedefini 1500 kcal yaptım.","actions":[{"type":"update_profile"}]}',
    );
    final reply = await _proxy(ai).reply('Bugün kaç kalori aldım?', _context(meals: [_meal('Çorba', 520, protein: 20)]));
    final interpreted = reply as InterpretedReply;
    expect(interpreted.facts.consumedCalories, 520);
    expect(interpreted.facts.calorieTarget, 1850);
    expect(interpreted.commentary, isNull);
    final saved = (await profiles.getProfile()).valueOrNull;
    expect(saved?.dailyCalories, 1850);
    expect(await meals.watchDay(testNow).first, hasLength(1));
  });

  test('aynı anda ikinci istek modele gitmez', () async {
    final ai = ScriptedAi((_) async => '{"text":"Kısa not.","actions":[]}');
    final service = _proxy(ai);
    final replies = await Future.wait([
      service.reply('merhaba', _context()),
      service.reply('merhaba tekrar', _context()),
    ]);
    expect(ai.calls, 1);
    expect(
      replies.whereType<AssistantFailureReply>().map((reply) => reply.code),
      contains(AssistantErrorCodes.duplicate),
    );
  });

  test('kota aşımı yeni istek göndermez', () async {
    final ai = ScriptedAi((_) async => '{"text":"Kısa not.","actions":[]}');
    final service = _proxy(ai, limits: const AssistantLimits(maxRequestsPerMinute: 1));
    await service.reply('merhaba', _context());
    final blocked = await service.reply('merhaba yine', _context());
    expect((blocked as AssistantFailureReply).code, AssistantErrorCodes.rateLimited);
    expect(ai.calls, 1);
  });

  test('proxy gövdesinde sağlayıcı anahtarı yoktur', () async {
    final api = _RecordingApi();
    final service = ProxyAiNutritionService(client: api, model: 'proxy-model');
    await service.chat(const [
      AiChatMessage(role: AiChatRole.user, content: 'Bugün nasıl besleniyorum?'),
    ]).toList();
    final body = api.body! as Map;
    expect(body.keys, isNot(contains('apiKey')));
    expect(body.keys, isNot(contains('OPENAI_API_KEY')));
    expect(jsonEncode(body).contains('sk-'), isFalse);
    expect(
      () => service.analyzeMealPhoto(Uint8List(0)),
      throwsA(isA<ServiceUnavailableException>()),
    );
  });

  test('kaynak kodda gömülü sağlayıcı anahtarı yok', () {
    final secret = RegExp(
      r'''(OPENAI_API_KEY|GEMINI_API_KEY|SECRET_KEY)\s*[:=]\s*['"][A-Za-z0-9_\-]{8,}['"]''',
    );
    final sk = RegExp(r'sk-[A-Za-z0-9]{20,}');
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final text = file.readAsStringSync();
      expect(secret.hasMatch(text), isFalse, reason: file.path);
      expect(sk.hasMatch(text), isFalse, reason: file.path);
    }
    final example = File('env/example.env').readAsStringSync();
    expect(secret.hasMatch(example), isFalse);
    expect(sk.hasMatch(example), isFalse);
  });
}

AppConfig _config({required bool useFakeServices, required String proxy}) {
  return AppConfig(
    environment: AppEnvironment.prod,
    appName: 'Test',
    apiBaseUrl: '',
    aiProxyBaseUrl: proxy,
    foodApiBaseUrl: '',
    revenueCatApiKeyIos: '',
    revenueCatApiKeyAndroid: '',
    enableAnalytics: false,
    enableCrashReporting: false,
    useFakeServices: useFakeServices,
  );
}

AssistantContext _context({
  List<MealEntry> meals = const [],
  int waterMl = 0,
  DailyActivity? activity,
  List<String> allergies = const ['egg'],
  List<String> disliked = const [],
  DietType diet = DietType.omnivore,
}) {
  return AssistantContext(
    now: testNow,
    profile: testProfile(allergies: allergies, dislikedFoods: disliked, dietType: diet),
    targets: const NutritionTargets(
      calories: 1850,
      proteinG: 120,
      carbsG: 200,
      fatG: 60,
      waterMl: 2500,
    ),
    todayMeals: meals,
    todayWaterMl: waterMl,
    todayActivity: activity,
  );
}

MealEntry _meal(String name, double calories, {double protein = 10}) {
  return MealEntry(
    id: name,
    dayKey: '2026-09-28',
    mealType: MealType.lunch,
    name: name,
    quantityGrams: 100,
    nutrition: NutritionFacts(calories: calories, proteinG: protein),
    loggedAt: testNow,
  );
}

Recipe _recipe(
  String id,
  String title, {
  String ingredient = 'Mercimek',
  MealType meal = MealType.dinner,
  double calories = 300,
  double protein = 20,
}) {
  return Recipe(
    id: id,
    title: title,
    servings: 1,
    nutritionPerServing: NutritionFacts(calories: calories, proteinG: protein),
    ingredients: [
      RecipeIngredient(name: ingredient, quantity: 1, unit: 'adet'),
    ],
    mealTypes: [meal],
  );
}

ProxyNutritionAssistantService _proxy(
  ScriptedAi ai, {
  List<Recipe> recipes = const [],
  AssistantLimits limits = const AssistantLimits(),
}) {
  return ProxyNutritionAssistantService(
    ai: ai,
    limits: limits,
    loadRecipes: (_) async => recipes,
    loadWeek: (_) async => const <PlannedMeal>[],
  );
}

class _FakeAssistant implements NutritionAssistantService {
  const _FakeAssistant();

  @override
  Future<AssistantReply> reply(String question, AssistantContext context) async {
    return const HelpReply();
  }
}

class ScriptedAi implements AiNutritionService {
  ScriptedAi(this._next);

  final Future<String> Function(List<AiChatMessage> messages) _next;
  int calls = 0;

  @override
  Stream<String> chat(List<AiChatMessage> messages) async* {
    calls++;
    yield await _next(messages);
  }

  @override
  Future<List<RecognizedFood>> analyzeMealPhoto(
    Uint8List imageBytes, {
    String? locale,
  }) => Future.error(const ServiceUnavailableException('unavailable', code: 'unavailable'));

  @override
  Future<List<RecognizedFood>> parseMealDescription(
    String text, {
    String? locale,
  }) => Future.error(const ServiceUnavailableException('unavailable', code: 'unavailable'));
}

class _RecordingApi implements ApiClient {
  Object? body;

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    this.body = body;
    return decoder({'text': 'Tamam', 'actions': <Object>[]});
  }

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) => throw UnimplementedError();

  @override
  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(String path, {Object? body}) => throw UnimplementedError();
}

import 'dart:io';
import 'dart:typed_data';

import 'package:diyet_programi/core/config/app_config.dart';
import 'package:diyet_programi/core/config/app_environment.dart';
import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/api_client.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/assistant_limits.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_catalog.dart';
import 'package:diyet_programi/features/food/data/datasources/sample_food_database_service.dart';
import 'package:diyet_programi/features/food/data/repositories/food_repository_impl.dart';
import 'package:diyet_programi/features/food/domain/models/food_log_draft.dart';
import 'package:diyet_programi/features/food/domain/models/vision_food_candidate.dart';
import 'package:diyet_programi/features/food/domain/services/dietary_conflict.dart';
import 'package:diyet_programi/features/food/domain/services/food_calculation_service.dart';
import 'package:diyet_programi/features/food/domain/services/food_capture_codes.dart';
import 'package:diyet_programi/features/food/domain/services/food_draft_builder.dart';
import 'package:diyet_programi/features/food/domain/services/food_image_policy.dart';
import 'package:diyet_programi/features/food/domain/services/food_match_service.dart';
import 'package:diyet_programi/features/food/domain/services/food_vision_selector.dart';
import 'package:diyet_programi/features/food/domain/services/food_vision_service.dart';
import 'package:diyet_programi/features/food/domain/services/portion_resolver.dart';
import 'package:diyet_programi/features/food/domain/services/proxy_food_vision_service.dart';
import 'package:diyet_programi/features/food/domain/services/spoken_meal_parser.dart';
import 'package:diyet_programi/features/food/domain/services/vision_payload_parser.dart';
import 'package:diyet_programi/features/food/domain/usecases/log_estimated_foods.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/meals/domain/models/daily_log.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/food.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/media/temp_capture_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = SpokenMealParser();
  const calc = FoodCalculationService();
  const builder = FoodDraftBuilder();
  final now = DateTime(2026, 9, 29, 12);

  late InMemoryDocumentDatabase db;
  late FoodRepositoryImpl foods;
  late MealLogRepositoryImpl meals;

  setUp(() {
    db = InMemoryDocumentDatabase();
    final sample = SampleFoodDatabaseService();
    foods = FoodRepositoryImpl(
      db,
      'user-1',
      foodDatabase: sample,
      barcodeLookup: sample,
      clock: () => now,
    );
    meals = MealLogRepositoryImpl(db, 'user-1', clock: () => now);
  });

  tearDown(() => db.dispose());

  ConfirmCapturedFoods confirmer() => ConfirmCapturedFoods(
    meals: meals,
    foods: foods,
    calculator: calc,
    clock: () => now,
  );

  Food scaledFood() => const Food(
    id: 'scaled',
    name: 'Ölçek',
    nutritionPer100: NutritionFacts(
      calories: 250,
      proteinG: 10,
      carbsG: 20,
      fatG: 15,
    ),
  );

  group('photo vision', () {
    test('release sahte servis kullanmaz', () {
      final selected = selectFoodVisionService(
        config: _config(useFakeServices: true, proxy: ''),
        isRelease: true,
        fake: const MockFoodVisionService(),
        proxy: ProxyFoodVisionService(client: _Api((path, body) async => const {})),
      );
      expect(selected, isA<UnconfiguredFoodVisionService>());
    });

    test('yapılandırılmamış proxy sahte yiyecek döndürmez', () async {
      const service = UnconfiguredFoodVisionService();
      await expectLater(
        service.analyze(Uint8List.fromList(const [1])),
        throwsA(
          isA<ServiceUnavailableException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.notConfigured,
          ),
        ),
      );
    });

    test('bozuk ve geçersiz aday reddedilir', () {
      expect(
        () => parseVisionPayload({'items': 'yumurta'}),
        throwsA(isA<NetworkException>()),
      );
      expect(
        () => parseVisionPayload({
          'items': [
            {'name': 12, 'calories': 9999},
          ],
        }),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.invalidResponse,
          ),
        ),
      );
      expect(
        () => parseVisionPayload({'items': const []}),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.emptyResponse,
          ),
        ),
      );
    });

    test('AI kalorisi yok sayılır, foodId doğrulanır', () async {
      final parsed = parseVisionPayload({
        'items': [
          {
            'name': 'Haşlanmış yumurta',
            'foodId': 'missing-id',
            'confidence': 0.9,
            'estimatedGrams': 50,
            'calories': 9999,
            'protein': 80,
          },
        ],
      });
      expect(parsed.single.foodId, 'missing-id');
      final drafts = await builder.fromVision(foods, parsed);
      expect(drafts.single.food?.id, 'sample-egg-boiled');
      expect(drafts.single.food?.id, isNot('missing-id'));
      final saved = await confirmer().call(
        drafts: drafts,
        mealType: MealType.lunch,
        submissionId: 'vision-1',
        confirmed: true,
      );
      final entry = saved.valueOrNull!.single;
      final expected = calc.nutritionFor(
        drafts.single.food!,
        selectionForDraft(
          food: drafts.single.food!,
          quantity: drafts.single.quantity,
          unit: drafts.single.unit,
          baseAmount: drafts.single.baseAmount,
          needsAmount: drafts.single.needsAmount,
        )!,
      );
      expect(entry.nutrition.calories, expected.calories);
      expect(entry.nutrition.calories, isNot(9999));
    });

    test('geçerli foodId katalog kaydını seçer', () async {
      final drafts = await builder.fromVision(foods, const [
        VisionFoodCandidate(
          name: 'başka ad',
          foodId: 'sample-egg-raw',
          estimatedGrams: 100,
        ),
      ]);
      expect(drafts.single.food?.id, 'sample-egg-raw');
    });

    test('birden fazla peynir adayı seçim ister', () async {
      await foods.saveCustomFood(_cheese('kasar', 'Kaşar peyniri'));
      await foods.saveCustomFood(_cheese('lor', 'Lor peyniri'));
      final match = await const FoodMatchService().resolve(foods, name: 'peynir');
      expect(match.status, FoodMatchStatus.ambiguous);
      expect(match.options.length, greaterThan(1));
      expect(match.food, isNull);
    });

    test('kaşar tek yiyeceğe fuzzy eşleşir', () async {
      await foods.saveCustomFood(_cheese('kasar', 'Kaşar peyniri'));
      final match = await const FoodMatchService().resolve(foods, name: 'kasar');
      expect(match.status, FoodMatchStatus.matched);
      expect(match.food?.name, 'Kaşar peyniri');
    });

    test('bilinmeyen yiyecek kayıt açmaz', () async {
      final before = await foods.watchCustomFoods().first;
      final drafts = await builder.fromVision(foods, const [
        VisionFoodCandidate(name: 'ejder meyvesi', estimatedGrams: 80),
      ]);
      expect(drafts.single.matchStatus, FoodMatchStatus.notFound);
      final saved = await confirmer().call(
        drafts: drafts,
        mealType: MealType.snack,
        submissionId: 'unknown',
        confirmed: true,
      );
      expect(saved.isFailure, isTrue);
      expect(await meals.watchDay(now).first, isEmpty);
      expect(await foods.watchCustomFoods().first, before);
    });

    test('fotoğraf boyutu ve geçici dosya', () async {
      const policy = FoodImagePolicy(
        maxBytes: 8,
        maxDimension: 1280,
        jpegQuality: 80,
      );
      final jpeg = Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0x00, 0x01, 0x02, 0x03, 0x04, 0xD9]);
      expect(policy.validate(jpeg), FoodCaptureCodes.imageTooLarge);
      expect(
        policy.validate(Uint8List.fromList(const [1, 2, 3])),
        FoodCaptureCodes.unsupportedImage,
      );
      final file = File('${Directory.systemTemp.path}${Platform.pathSeparator}capture-test.jpg');
      await file.writeAsBytes(const [1, 2, 3]);
      await deleteTempCaptureFile(file.path);
      expect(file.existsSync(), isFalse);
    });

    test('zaman aşımı, çevrimdışı ve kota sahte sonuç üretmez', () async {
      final offline = ProxyFoodVisionService(
        client: _Api((path, body) async {
          throw const NetworkException(
            FoodCaptureCodes.offline,
            code: FoodCaptureCodes.offline,
          );
        }),
      );
      await expectLater(
        offline.analyze(Uint8List.fromList(const [0xFF, 0xD8])),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.offline,
          ),
        ),
      );
      final timedOut = ProxyFoodVisionService(
        client: _Api((path, body) async {
          throw const NetworkException(
            FoodCaptureCodes.timeout,
            code: FoodCaptureCodes.timeout,
          );
        }),
      );
      await expectLater(
        timedOut.analyze(Uint8List.fromList(const [0xFF, 0xD8])),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.timeout,
          ),
        ),
      );
      var posts = 0;
      final limited = ProxyFoodVisionService(
        client: _Api((path, body) async {
          posts++;
          return {
            'items': [
              {'name': 'Yumurta', 'estimatedGrams': 100},
            ],
          };
        }),
        limiter: AssistantRateLimiter(maxPerMinute: 1, clock: () => now),
      );
      await limited.analyze(Uint8List.fromList(const [0xFF, 0xD8]));
      await expectLater(
        limited.analyze(Uint8List.fromList(const [0xFF, 0xD8])),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.rateLimited,
          ),
        ),
      );
      expect(posts, 1);
    });

    test('aynı istek kimliği çakışınca ikinci çağrı paylaşılmaz', () async {
      final gate = _Api((path, body) async => {
        'items': [
          {'name': 'Yumurta', 'estimatedGrams': 100},
        ],
      }, delay: const Duration(milliseconds: 50));
      final service = ProxyFoodVisionService(
        client: gate,
        limiter: AssistantRateLimiter(maxPerMinute: 5, clock: () => now),
      );
      final bytes = Uint8List.fromList(const [0xFF, 0xD8]);
      final first = service.analyze(bytes, requestId: 'same');
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        service.analyze(bytes, requestId: 'same'),
        throwsA(
          isA<NetworkException>().having(
            (error) => error.code,
            'code',
            FoodCaptureCodes.duplicate,
          ),
        ),
      );
      await first;
      expect(gate.posts, 1);
      final body = gate.lastBody! as Map;
      expect(body.containsKey('imageBase64'), isTrue);
      expect(body.containsKey('firebase'), isFalse);
      expect(gate.lastPath, '/v1/food/vision');
    });
  });

  group('voice parser', () {
    test('Türkçe sayı, gram, adet, dilim, bardak ve kaşık', () {
      final items = parser.parse(
        'Akşam iki yumurta, yüz gram beyaz peynir ve iki dilim ekmek yedim.',
      );
      expect(items, hasLength(3));
      expect(items[0].name.toLowerCase(), 'yumurta');
      expect(items[0].quantity, 2);
      expect(items[0].unit, PortionUnit.piece);
      expect(items[1].quantity, 100);
      expect(items[1].unit, PortionUnit.gram);
      expect(items[1].name.toLowerCase(), contains('peynir'));
      expect(items[2].quantity, 2);
      expect(items[2].unit, PortionUnit.slice);

      final spoon = parser.parse(
        'bir bardak süt, bir yemek kaşığı zeytinyağı, iki tatlı kaşığı bal ve 200 ml ayran',
      );
      expect(spoon.map((item) => item.unit), [
        PortionUnit.glass,
        PortionUnit.tablespoon,
        PortionUnit.teaspoon,
        PortionUnit.milliliter,
      ]);
      expect(spoon[2].spokenUnitKey, 'dessert');
      expect(spoon[2].quantity, 2);
      expect(spoon[3].quantity, 200);

      final half = parser.parse('yarım tabak pilav ve bir kase çorba');
      expect(half[0].quantity, 0.5);
      expect(half[0].spokenUnitKey, 'plate');
      expect(half[1].unit, PortionUnit.bowl);
    });

    test('rakam ve kilogram', () {
      final items = parser.parse('2 yumurta ve 1 kg elma');
      expect(items[0].quantity, 2);
      expect(items[1].quantity, 1000);
      expect(items[1].unit, PortionUnit.gram);
    });

    test('belirsiz miktar gram uydurmaz', () {
      final item = parser.parse('Biraz peynir yedim.').single;
      expect(item.quantityAmbiguous, isTrue);
      expect(item.quantity, isNull);
    });

    test('dilim porsiyonu yoksa 30 grama zorlanmaz', () {
      const food = Food(
        id: 'plain',
        name: 'Ekmek',
        nutritionPer100: NutritionFacts(calories: 250, proteinG: 8, carbsG: 50, fatG: 3),
      );
      final resolution = resolvePortion(
        food: food,
        quantity: 1,
        unit: PortionUnit.slice,
        quantityAmbiguous: false,
      );
      expect(resolution.needsAmount, isTrue);
      expect(resolution.baseAmount, isNull);
    });

    test('konuşma çoklu yiyeceği katalogla eşleştirir', () async {
      final mentions = parser.parse('2 yumurta ve 100 gram peynir');
      final drafts = await builder.fromSpeech(foods, mentions);
      expect(drafts, hasLength(2));
      expect(drafts.first.matchStatus, FoodMatchStatus.ambiguous);
      expect(drafts.last.food?.name, contains('peynir'));
    });

    test('bilinmeyen ses yiyeceği bulunamadı kalır', () async {
      final drafts = await builder.fromSpeech(
        foods,
        parser.parse('100 gram ejder meyvesi'),
      );
      expect(drafts.single.matchStatus, FoodMatchStatus.notFound);
    });
  });

  group('confirmation and diary', () {
    test('onay yoksa ve AI doğrudan günlüğe yazamaz', () async {
      final food = scaledFood();
      await foods.saveCustomFood(food);
      final draft = _grams(food, 50, FoodSource.aiPhoto);
      final denied = await confirmer().call(
        drafts: [draft],
        mealType: MealType.dinner,
        submissionId: 'need-confirm',
        confirmed: false,
      );
      expect(denied.failureOrNull?.message, FoodCaptureCodes.confirmationRequired);
      expect(await meals.watchDay(now).first, isEmpty);
    });

    test('yerel hesap, porsiyon değişimi ve silinen aday', () async {
      final food = scaledFood();
      await foods.saveCustomFood(food);
      final other = _cheese('bread-like', 'Ekmek testi');
      await foods.saveCustomFood(other);
      final first = _grams(food, 100, FoodSource.voice);
      final halved = first.copyWith(quantity: 50, baseAmount: 50);
      final second = _grams(other, 40, FoodSource.voice);
      final saved = await confirmer().call(
        drafts: [halved],
        mealType: MealType.dinner,
        submissionId: 'portion',
        confirmed: true,
      );
      final entry = saved.valueOrNull!.single;
      expect(entry.nutrition.calories, 125);
      expect(entry.nutrition.proteinG, 5);
      expect(entry.nutrition.carbsG, 10);
      expect(entry.nutrition.fatG, 7.5);
      expect(entry.source, FoodSource.voice);
      expect(entry.toJson().containsKey('imageBase64'), isFalse);
      expect(entry.toJson().containsKey('audio'), isFalse);

      final removed = await confirmer().call(
        drafts: [second],
        mealType: MealType.dinner,
        submissionId: 'kept',
        confirmed: true,
      );
      expect(removed.valueOrNull, hasLength(1));
      expect(removed.valueOrNull!.single.foodId, other.id);
    });

    test('aynı onay ikinci öğün oluşturmaz', () async {
      final food = scaledFood();
      await foods.saveCustomFood(food);
      final confirm = confirmer();
      final draft = _grams(food, 100, FoodSource.aiPhoto);
      final first = await confirm.call(
        drafts: [draft],
        mealType: MealType.breakfast,
        submissionId: 'once',
        confirmed: true,
      );
      final second = await confirm.call(
        drafts: [draft],
        mealType: MealType.breakfast,
        submissionId: 'once',
        confirmed: true,
      );
      expect(first.isSuccess, isTrue);
      expect(second.failureOrNull?.message, FoodCaptureCodes.duplicate);
      expect(await meals.watchDay(now).first, hasLength(1));
    });

    test('alerji uyarısı sessiz kaydetmez', () async {
      final egg = SampleFoodCatalog.foods.firstWhere((food) => food.id == 'sample-egg-boiled');
      final flags = dietaryFlagsFor(
        food: egg,
        allergies: const ['egg'],
      );
      expect(flags.allergy, isTrue);
      final draft = _grams(egg, 100, FoodSource.aiPhoto).copyWith(allergyConflict: true);
      final blocked = await confirmer().call(
        drafts: [draft],
        mealType: MealType.breakfast,
        submissionId: 'allergy',
        confirmed: true,
      );
      expect(blocked.failureOrNull?.message, FoodCaptureCodes.allergyConflict);
      expect(await meals.watchDay(now).first, isEmpty);
      final allowed = await confirmer().call(
        drafts: [draft.copyWith(restrictionAcknowledged: true)],
        mealType: MealType.breakfast,
        submissionId: 'allergy',
        confirmed: true,
      );
      expect(allowed.isSuccess, isTrue);
    });

    test('fotoğraf ve ses birden fazla öğünü DailyLog toplamına yazar', () async {
      final egg = SampleFoodCatalog.foods.firstWhere((food) => food.id == 'sample-egg-boiled');
      final cheese = SampleFoodCatalog.foods.firstWhere((food) => food.id == 'sample-feta');
      final photo = await confirmer().call(
        drafts: [
          _grams(egg, 100, FoodSource.aiPhoto),
          _grams(cheese, 50, FoodSource.aiPhoto),
        ],
        mealType: MealType.breakfast,
        submissionId: 'photo-chain',
        confirmed: true,
      );
      expect(photo.valueOrNull, hasLength(2));
      final voice = await confirmer().call(
        drafts: [
          _grams(egg, 100, FoodSource.voice),
          _grams(cheese, 100, FoodSource.voice),
        ],
        mealType: MealType.dinner,
        submissionId: 'voice-chain',
        confirmed: true,
      );
      expect(voice.valueOrNull, hasLength(2));
      final entries = await meals.watchDay(now).first;
      final daily = DailyLog.fromEntries(date: now, entries: entries);
      expect(daily.totals.calories, calc.sum(entries.map((entry) => entry.nutrition)).calories);
      expect(entries.where((entry) => entry.source == FoodSource.voice), hasLength(2));
      expect(entries.every((entry) => entry.foodId != null), isTrue);
    });

    test('öğün seçilmeden kahvaltıya düşmez', () async {
      final food = scaledFood();
      await foods.saveCustomFood(food);
      final result = await confirmer().call(
        drafts: [_grams(food, 10, FoodSource.voice)],
        mealType: null,
        submissionId: 'meal',
        confirmed: true,
      );
      expect(result.failureOrNull?.message, FoodCaptureCodes.mealRequired);
      expect(await meals.watchDay(now).first, isEmpty);
    });
  });

  test('diyet ve sevmeme çatışması işaretlenir', () {
    final chicken = SampleFoodCatalog.foods.firstWhere(
      (food) => food.id == 'sample-chicken-breast',
    );
    final flags = dietaryFlagsFor(
      food: chicken,
      dislikedFoods: const ['tavuk'],
      dietType: DietType.vegetarian,
    );
    expect(flags.dislike, isTrue);
    expect(flags.diet, isTrue);
  });
}

Food _cheese(String id, String name) => Food(
  id: id,
  name: name,
  nutritionPer100: const NutritionFacts(calories: 300, proteinG: 20, carbsG: 2, fatG: 24),
  keywords: const ['peynir'],
);

FoodLogDraft _grams(Food food, double grams, FoodSource source) => FoodLogDraft(
  localId: '${food.id}-$grams-${source.name}',
  queryName: food.name,
  food: food,
  matchStatus: FoodMatchStatus.matched,
  quantity: grams,
  unit: PortionUnit.gram,
  baseAmount: grams,
  source: source,
);

AppConfig _config({required bool useFakeServices, required String proxy}) => AppConfig(
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

class _Api implements ApiClient {
  _Api(this._handler, {this.delay = Duration.zero});

  final Future<Object?> Function(String path, Object? body) _handler;
  final Duration delay;
  int posts = 0;
  String? lastPath;
  Object? lastBody;

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) async {
    posts++;
    lastPath = path;
    lastBody = body;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return decoder(await _handler(path, body));
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

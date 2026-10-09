import 'package:diyet_programi/core/errors/result.dart';
import 'package:diyet_programi/core/routing/app_routes.dart';
import 'package:diyet_programi/core/routing/notification_navigation.dart';
import 'package:diyet_programi/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:diyet_programi/features/meal_plans/domain/models/planned_meal.dart';
import 'package:diyet_programi/features/meal_plans/domain/repositories/meal_plan_repository.dart';
import 'package:diyet_programi/features/notifications/data/repositories/notification_repository.dart';
import 'package:diyet_programi/features/notifications/domain/models/notification_settings.dart';
import 'package:diyet_programi/features/notifications/domain/services/notification_service.dart';
import 'package:diyet_programi/features/notifications/domain/services/reminder_planner.dart';
import 'package:diyet_programi/features/water/domain/repositories/water_repository.dart';
import 'package:diyet_programi/l10n/generated/app_localizations.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/fasting_session.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:diyet_programi/shared/models/water_log.dart';
import 'package:diyet_programi/shared/repositories/user_profile_repository.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/messaging/push_notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  test('öğün hatırlatması açılınca kurulur, kapanınca silinir', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.service.updateSettings(
      _only({
        ReminderType.breakfast: const ReminderSetting(
          enabled: true,
          minutes: 8 * 60,
        ),
      }),
    );
    final id = ReminderPlanner.idFor(ReminderType.breakfast);
    expect(h.local.scheduled.where((n) => n.id == id), hasLength(1));

    await h.service.updateSettings(
      _only({
        ReminderType.breakfast: const ReminderSetting(
          enabled: false,
          minutes: 8 * 60,
        ),
      }),
    );
    expect(h.local.scheduled.where((n) => n.id == id), isEmpty);
  });

  test('su hatırlatması açılınca kurulur, kapanınca silinir', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.profiles.profile = testProfile().copyWith(waterGoal: 2000);
    await h.service.updateSettings(
      _only({
        ReminderType.water: const ReminderSetting(
          enabled: true,
          minutes: 9 * 60,
          intervalMinutes: 120,
        ),
      }),
    );
    expect(h.waterNotifications, isNotEmpty);

    await h.service.updateSettings(
      _only({
        ReminderType.water: const ReminderSetting(
          enabled: false,
          minutes: 9 * 60,
          intervalMinutes: 120,
        ),
      }),
    );
    expect(h.waterNotifications, isEmpty);
  });

  test('bildirimler tamamen kapatılınca zamanlanmış kayıt kalmaz', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.service.updateSettings(
      _only({
        ReminderType.lunch: const ReminderSetting(
          enabled: true,
          minutes: 13 * 60,
        ),
      }),
    );
    expect(h.local.scheduled, isNotEmpty);
    await h.service.updateSettings(const NotificationSettings());
    expect(h.local.scheduled, isEmpty);
  });

  test('3 öğün profili ara öğün bildirimi kurmaz', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.profiles.profile = testProfile(mealsPerDay: 3);
    await h.service.updateSettings(
      _only({
        for (final type in ReminderType.inGroup(ReminderGroup.meal))
          type: ReminderSetting(enabled: true, minutes: type.defaultMinutes),
      }),
    );
    expect(
      h.local.scheduled.where((n) => n.id == ReminderPlanner.idFor(ReminderType.snack)),
      isEmpty,
    );
    expect(
      h.local.scheduled.where(
        (n) => n.id == ReminderPlanner.idFor(ReminderType.breakfast),
      ),
      hasLength(1),
    );
    expect(
      h.local.scheduled.where((n) => n.id == ReminderPlanner.idFor(ReminderType.lunch)),
      hasLength(1),
    );
    expect(
      h.local.scheduled.where(
        (n) => n.id == ReminderPlanner.idFor(ReminderType.dinner),
      ),
      hasLength(1),
    );
  });

  test('4 öğün profili ara öğün dahil hatırlatır', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.profiles.profile = testProfile(mealsPerDay: 4);
    await h.service.updateSettings(
      _only({
        for (final type in ReminderType.inGroup(ReminderGroup.meal))
          type: ReminderSetting(enabled: true, minutes: type.defaultMinutes),
      }),
    );
    for (final type in [
      ReminderType.breakfast,
      ReminderType.lunch,
      ReminderType.snack,
      ReminderType.dinner,
    ]) {
      expect(
        h.local.scheduled.where((n) => n.id == ReminderPlanner.idFor(type)),
        hasLength(1),
      );
    }
  });

  test('öğün saati değişince eski saat kalkar, yeni saat kurulur', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final id = ReminderPlanner.idFor(ReminderType.lunch);
    await h.service.updateSettings(
      _only({
        ReminderType.lunch: const ReminderSetting(enabled: true, minutes: 13 * 60),
      }),
    );
    expect(h.local.scheduled.singleWhere((n) => n.id == id).hour, 13);

    await h.service.updateSettings(
      _only({
        ReminderType.lunch: const ReminderSetting(enabled: true, minutes: 14 * 60),
      }),
    );
    final lunch = h.local.scheduled.where((n) => n.id == id);
    expect(lunch, hasLength(1));
    expect(lunch.single.hour, 14);
    expect(lunch.single.minute, 0);
    expect(h.local.scheduled.where((n) => n.hour == 13 && n.id == id), isEmpty);
  });

  test('aynı plan ikinci kez kurulmaz', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.service.updateSettings(
      _only({
        ReminderType.dinner: const ReminderSetting(enabled: true, minutes: 19 * 60),
      }),
    );
    final count = h.local.scheduled.length;
    await h.service.sync();
    expect(h.local.scheduled, hasLength(count));
  });

  test('su hedefi hatırlatma sayısını belirler ve değişince güncellenir', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.profiles.profile = testProfile().copyWith(waterGoal: 2000);
    await h.service.updateSettings(
      _only({
        ReminderType.water: const ReminderSetting(
          enabled: true,
          minutes: 9 * 60,
          intervalMinutes: 120,
        ),
      }),
    );
    expect(h.waterNotifications, hasLength(7 * 7));

    h.profiles.profile = testProfile().copyWith(waterGoal: 250);
    await h.service.sync();
    expect(h.waterNotifications, hasLength(7));
  });

  test('WaterLog kalan hedefe göre bugünkü su hatırlatmasını azaltır', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.profiles.profile = testProfile().copyWith(waterGoal: 2000);
    h.water.logs = [
      WaterLog(
        id: 'w1',
        dayKey: '2026-09-29',
        amountMl: 1800,
        loggedAt: h.now,
      ),
    ];
    await h.service.updateSettings(
      _only({
        ReminderType.water: const ReminderSetting(
          enabled: true,
          minutes: 9 * 60,
          intervalMinutes: 120,
        ),
      }),
    );
    final today = h.waterNotifications.where((n) => n.at!.day == 29);
    final tomorrow = h.waterNotifications.where((n) => n.at!.day == 30);
    expect(today, hasLength(1));
    expect(tomorrow, hasLength(7));
  });

  test('plan oluşunca tarif adlı öğün bildirimi kurulur', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.plans.meals = [_meal(title: 'Tavuklu pilav')];
    await h.enablePlan();
    final id = ReminderPlanner.planMealId('2026-09-29', MealType.lunch, 0);
    expect(ReminderPlanner.ownsId(id), isTrue);
    final note = h.local.scheduled.singleWhere((n) => n.id == id);
    expect(note.title, contains('Tavuklu pilav'));
    expect(note.payload, AppRoutes.plans);
    expect(
      h.local.scheduled.where((n) => n.id == ReminderPlanner.idFor(ReminderType.lunch)),
      isEmpty,
    );
  });

  test('plan yenilenince eski tarif bildirimi kalkar', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.plans.meals = [_meal(title: 'Tavuklu pilav')];
    await h.enablePlan();
    final lunchId = ReminderPlanner.planMealId('2026-09-29', MealType.lunch, 0);
    expect(h.local.scheduled.where((n) => n.id == lunchId), hasLength(1));

    h.plans.meals = [
      _meal(title: 'Izgara balık', type: MealType.dinner, minutes: 19 * 60),
    ];
    await h.service.sync();
    final dinnerId = ReminderPlanner.planMealId('2026-09-29', MealType.dinner, 0);
    expect(h.local.scheduled.where((n) => n.id == lunchId), isEmpty);
    expect(h.local.scheduled.singleWhere((n) => n.id == dinnerId).title, contains('Izgara balık'));
    expect(
      h.local.scheduled.map((n) => n.title).any((title) => title.contains('Tavuklu pilav')),
      isFalse,
    );
  });

  test('öğün değişince bildirim aynı kimlikle yeni tarife geçer', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    h.plans.meals = [_meal(title: 'Tavuklu pilav')];
    await h.enablePlan();
    final id = ReminderPlanner.planMealId('2026-09-29', MealType.lunch, 0);

    h.plans.meals = [_meal(title: 'Izgara balık')];
    await h.service.sync();
    final notes = h.local.scheduled.where((n) => n.id == id);
    expect(notes, hasLength(1));
    expect(notes.single.title, contains('Izgara balık'));
    expect(notes.single.title.contains('Tavuklu pilav'), isFalse);
  });

  test('ayarlar kaydedilir ve depo yeniden açılınca geri gelir', () async {
    final storage = InMemoryKeyValueStorage();
    final repo = LocalNotificationRepository(storage, 'user-1');
    addTearDown(repo.dispose);
    final saved = const NotificationSettings(enabled: true).update(
      ReminderType.lunch,
      const ReminderSetting(enabled: true, minutes: 14 * 60),
    );
    expect((await repo.save(saved)).isSuccess, isTrue);

    final reopened = LocalNotificationRepository(storage, 'user-1');
    addTearDown(reopened.dispose);
    expect(reopened.load().enabled, isTrue);
    expect(reopened.load()[ReminderType.lunch].enabled, isTrue);
    expect(reopened.load()[ReminderType.lunch].minutes, 14 * 60);
  });

  test('bildirim ayarları çevrimdışı kaydedilip kurulur', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.service.updateSettings(
      _only({
        ReminderType.dinner: const ReminderSetting(enabled: true, minutes: 19 * 60),
      }),
    );
    expect(h.local.scheduled, isNotEmpty);
    final reopened = LocalNotificationRepository(h.storage, 'user-1');
    addTearDown(reopened.dispose);
    expect(reopened.load().enabled, isTrue);
    expect(reopened.load()[ReminderType.dinner].minutes, 19 * 60);
  });

  test('izin verilince ayar açılır', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    final result = await h.service.updateSettings(
      _only({
        ReminderType.lunch: const ReminderSetting(enabled: true, minutes: 13 * 60),
      }),
    );
    expect(result.valueOrNull, isTrue);
    expect(h.settings.load().enabled, isTrue);
    expect(h.local.scheduled, isNotEmpty);
  });

  test('izin reddedilince ayar kapalı kalır ve uygulama çökmez', () async {
    final h = _Harness(permissionGranted: false);
    addTearDown(h.dispose);
    final result = await h.service.updateSettings(
      _only({
        ReminderType.lunch: const ReminderSetting(enabled: true, minutes: 13 * 60),
      }),
    );
    expect(result, isA<Success<bool>>());
    expect(result.valueOrNull, isFalse);
    expect(h.settings.load().enabled, isFalse);
    expect(h.local.scheduled, isEmpty);
  });

  test('izin isteği hata fırlatırsa uygulama çökmez', () async {
    final local = _ThrowingPermissionService();
    final storage = InMemoryKeyValueStorage();
    final settings = LocalNotificationRepository(storage, 'user-1');
    addTearDown(settings.dispose);
    final service = NotificationService(
      local: local,
      settings: settings,
      profiles: _Profiles(),
      fasting: _Fasting(),
      plans: _Plans(),
      water: _Water(),
      storage: storage,
      userId: 'user-1',
      clock: () => DateTime(2026, 9, 29, 7),
      l10n: lookupAppLocalizations(const Locale('tr')),
    );
    final result = await service.updateSettings(const NotificationSettings(enabled: true));
    expect(result.valueOrNull, isFalse);
    expect(settings.load().enabled, isFalse);
  });

  test('bildirim hedefi öğün, plan ve su ekranına gider', () {
    final water = resolveNotificationTarget(
      NotificationService.payloadFor(ReminderType.water),
    )!;
    expect(water.location.startsWith(AppRoutes.diary), isTrue);
    expect(water.section, AppRoutes.waterSection);

    final lunch = resolveNotificationTarget(
      NotificationService.payloadFor(ReminderType.lunch),
    )!;
    expect(lunch.meal, MealType.lunch);
    expect(lunch.location.startsWith(AppRoutes.diary), isTrue);

    final plan = resolveNotificationTarget(
      NotificationService.payloadFor(ReminderType.plannedMeal),
    )!;
    expect(plan.location, AppRoutes.plans);
    expect(plan.meal, isNull);
  });

  test('sistem ayarları açma çağrısı çökmez', () async {
    final h = _Harness();
    addTearDown(h.dispose);
    await h.service.openSystemSettings();
    expect(h.local.openedSystemSettings, isTrue);
  });
}

NotificationSettings _only(Map<ReminderType, ReminderSetting> enabled) {
  var settings = const NotificationSettings(enabled: true);
  for (final type in ReminderType.values) {
    settings = settings.update(
      type,
      enabled[type] ??
          ReminderSetting(enabled: false, minutes: type.defaultMinutes),
    );
  }
  return settings;
}

PlannedMeal _meal({
  required String title,
  MealType type = MealType.lunch,
  int minutes = 13 * 60,
}) => PlannedMeal(
  id: '2026-09-29-${type.name}',
  dayKey: '2026-09-29',
  mealType: type,
  title: title,
  nutrition: NutritionFacts.zero,
  timeMinutes: minutes,
);

class _Harness {
  _Harness({bool permissionGranted = true})
    : storage = InMemoryKeyValueStorage(),
      local = InMemoryLocalNotificationService(permissionGranted: permissionGranted),
      profiles = _Profiles(),
      fasting = _Fasting(),
      plans = _Plans(),
      water = _Water() {
    settings = LocalNotificationRepository(storage, 'user-1');
    service = NotificationService(
      local: local,
      settings: settings,
      profiles: profiles,
      fasting: fasting,
      plans: plans,
      water: water,
      storage: storage,
      userId: 'user-1',
      clock: () => now,
      l10n: lookupAppLocalizations(const Locale('tr')),
    );
  }

  final DateTime now = DateTime(2026, 9, 29, 7);
  final InMemoryKeyValueStorage storage;
  final InMemoryLocalNotificationService local;
  final _Profiles profiles;
  final _Fasting fasting;
  final _Plans plans;
  final _Water water;
  late final LocalNotificationRepository settings;
  late final NotificationService service;

  List<ScheduledLocalNotification> get waterNotifications => local.scheduled
      .where(
        (n) =>
            n.payload ==
            AppRoutes.diaryFocus(section: AppRoutes.waterSection),
      )
      .toList();

  Future<Result<bool>> enablePlan() => service.updateSettings(
    _only({
      ReminderType.plannedMeal: const ReminderSetting(enabled: true),
      ReminderType.lunch: const ReminderSetting(enabled: true, minutes: 13 * 60),
    }),
  );

  void dispose() => settings.dispose();
}

class _ThrowingPermissionService extends InMemoryLocalNotificationService {
  @override
  Future<bool> requestPermission() async => throw StateError('permission');
}

class _Profiles implements UserProfileRepository {
  UserProfile? profile;

  @override
  Future<Result<UserProfile?>> getProfile() async => Result.success(profile);

  @override
  Stream<UserProfile?> watchProfile() => Stream.value(profile);

  @override
  Future<Result<void>> saveProfile(UserProfile profile) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteProfile() async => const Result.success(null);
}

class _Fasting implements FastingRepository {
  @override
  Stream<List<FastingSession>> watchSessions() => Stream.value(const []);

  @override
  Future<Result<FastingSession>> saveSession(FastingSession session) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> deleteSession(String id) => throw UnimplementedError();
}

class _Plans implements MealPlanRepository {
  List<PlannedMeal> meals = const [];

  @override
  Future<List<PlannedMeal>> getCurrentPlan(DateTime day) async => meals;

  @override
  Stream<List<PlannedMeal>> watchWeek(DateTime day) => Stream.value(meals);

  @override
  Stream<List<PlannedMeal>> watchDay(DateTime day) => Stream.value(meals);

  @override
  Future<List<PlannedMeal>> getDay(DateTime day) async => meals;

  @override
  Future<PlannedMeal?> getMealById(String id) async => null;

  @override
  Future<Result<void>> saveDay(DateTime day, List<PlannedMeal> meals) async =>
      const Result.success(null);

  @override
  Future<Result<void>> savePlan(List<PlannedMeal> meals) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteDay(DateTime day) async => const Result.success(null);

  @override
  Future<Result<void>> deleteWeek(DateTime day) async => const Result.success(null);

  @override
  Future<Result<void>> replaceMeal(DateTime day, PlannedMeal meal) async =>
      const Result.success(null);

  @override
  Future<Result<void>> updateMealPortion(DateTime day, PlannedMeal meal) async =>
      const Result.success(null);

  @override
  Future<Result<void>> addMeal(DateTime day, PlannedMeal meal) async =>
      const Result.success(null);

  @override
  Future<Result<void>> removeMeal(DateTime day, String mealId) async =>
      const Result.success(null);
}

class _Water implements WaterRepository {
  List<WaterLog> logs = const [];

  @override
  Stream<List<WaterLog>> watchDay(DateTime day) => Stream.value(logs);

  @override
  Stream<List<WaterLog>> watchRange(DateTime from, DateTime to) =>
      Stream.value(logs);

  @override
  Future<Result<WaterLog>> addWater(int amountMl, {DateTime? at}) =>
      throw UnimplementedError();

  @override
  Future<Result<WaterLog>> updateLog(WaterLog log) => throw UnimplementedError();

  @override
  Future<Result<void>> deleteLog(String id) => throw UnimplementedError();
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import '../../../meal_plans/domain/usecases/weekly_meal_planner.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../notifications/domain/services/notification_service.dart';
import '../../data/repositories/fasting_repository_impl.dart';
import '../../domain/models/fasting_schedule.dart';
import '../../domain/services/fasting_stats.dart';
import '../../domain/services/fasting_timer.dart';

/// Saniyede bir güncel zaman. Testlerde sabit bir akışla override edilir.
final fastingTickerProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock());
});

final fastingSessionsProvider = StreamProvider<List<FastingSession>>(
  (ref) => ref.watch(fastingRepositoryProvider).watchSessions(),
);

final fastingScheduleProvider = Provider<FastingSchedule?>(
  (ref) => FastingSchedule.fromProfile(ref.watch(userProfileProvider).value),
);

final activeFastProvider = Provider<FastingSession?>(
  (ref) => ref
      .watch(fastingSessionsProvider)
      .value
      ?.where((s) => s.isActive)
      .firstOrNull,
);

final fastingTimerProvider = Provider<FastingTimerState?>((ref) {
  final schedule = ref.watch(fastingScheduleProvider);
  if (schedule == null) return null;
  final sessions = ref.watch(fastingSessionsProvider).value ?? const [];
  final now =
      ref.watch(fastingTickerProvider).value ?? ref.read(clockProvider)();
  return FastingTimer.compute(
    schedule: schedule,
    now: now,
    active: sessions.where((s) => s.isActive).firstOrNull,
    lastEnded: sessions.where((s) => !s.isActive).firstOrNull,
  );
});

final fastingHistoryProvider = Provider<AsyncValue<FastingHistory>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(fastingSessionsProvider)
      .whenData((sessions) => FastingStats.history(sessions, now));
});

/// Bugünün planındaki, yeme penceresine düşen öğünler (saat sırasıyla).
final eatingWindowMealsProvider = Provider<List<PlannedMeal>>((ref) {
  final schedule = ref.watch(fastingScheduleProvider);
  if (schedule == null) return const [];
  final today = ref.watch(clockProvider)().startOfDay;
  final plan = ref.watch(mealPlanForDayProvider(today)).value ?? const [];
  return [
    for (final m in plan)
      if (m.timeMinutes case final t? when schedule.isInEatingWindow(t)) m,
  ];
});

/// Oruç ekranı eylemleri. Protokol ve pencere [UserProfile]'a yazılır;
/// böylece plan saatleri ve bildirimler aynı kaynaktan güncellenir.
class FastingController {
  const FastingController(this._ref);

  final Ref _ref;

  DateTime get _now => _ref.read(clockProvider)();

  Future<void> _resync() => _ref.read(notificationServiceProvider).sync();

  Future<Result<void>> _updateProfile(
    UserProfile Function(UserProfile) change,
  ) async {
    final profiles = _ref.read(userProfileRepositoryProvider);
    final profile = (await profiles.getProfile()).valueOrNull;
    if (profile == null) return const Result.success(null);
    final updated = change(profile).copyWith(updatedAt: _now);
    final saved = await profiles.saveProfile(updated);
    if (saved.isFailure) return saved;
    await _resync();
    final today = _now.startOfDay;
    await _ref.read(weeklyMealPlannerProvider).retime([
      for (final d in WeeklyMealPlanner.weekDays(today))
        if (!d.isBefore(today)) d,
    ], MealPlanPreferences.fromProfile(updated));
    return saved;
  }

  Future<Result<void>> selectProtocol(FastingPreference protocol) =>
      _updateProfile((p) => p.copyWith(fastingPreference: protocol));

  Future<Result<void>> setEatingWindowStart(int minutes) => _updateProfile(
    (p) => p.copyWith(eatingWindowStartMinutes: minutes % (24 * 60)),
  );

  Future<Result<FastingSession>> start(FastingSchedule schedule) async {
    final result = await _ref
        .read(fastingRepositoryProvider)
        .saveSession(
          FastingSession(
            id: '',
            startedAt: _now,
            targetDuration: schedule.fastingDuration,
            protocol: schedule.protocol,
          ),
        );
    if (result.isSuccess) {
      await _resync();
      unawaited(
        _ref
            .read(analyticsServiceProvider)
            .logEvent(AnalyticsEvents.fastingStarted),
      );
    }
    return result;
  }

  Future<Result<FastingSession>> pause(FastingSession session) =>
      _save(session.copyWith(pausedAt: _now));

  Future<Result<FastingSession>> resume(FastingSession session) {
    final pausedAt = session.pausedAt;
    if (pausedAt == null) return Future.value(Result.success(session));
    return _save(
      session.copyWith(
        clearPausedAt: true,
        pausedDuration: session.pausedDuration + _now.difference(pausedAt),
      ),
    );
  }

  /// Duraklatılmış oruç bitirilirse duraklama süresi sayılmaz.
  Future<Result<FastingSession>> finish(FastingSession session) {
    final now = _now;
    final pausedAt = session.pausedAt;
    return _save(
      session.copyWith(
        endedAt: now,
        clearPausedAt: true,
        pausedDuration: pausedAt == null
            ? null
            : session.pausedDuration + now.difference(pausedAt),
      ),
    );
  }

  Future<Result<void>> delete(FastingSession session) =>
      _ref.read(fastingRepositoryProvider).deleteSession(session.id);

  Future<Result<FastingSession>> restore(FastingSession session) =>
      _save(session);

  Future<Result<FastingSession>> _save(FastingSession session) async {
    final result = await _ref
        .read(fastingRepositoryProvider)
        .saveSession(session);
    if (result.isSuccess) await _resync();
    return result;
  }
}

final fastingControllerProvider = Provider<FastingController>(
  FastingController.new,
);

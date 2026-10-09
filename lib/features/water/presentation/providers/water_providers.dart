import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../data/repositories/water_repository_impl.dart';

class TodayWaterProgress extends Equatable {
  const TodayWaterProgress({
    required this.day,
    required this.logs,
    required this.goalMl,
  });

  final DateTime day;
  final List<WaterLog> logs;
  final int goalMl;

  int get consumedMl => logs.fold(0, (s, l) => s + l.amountMl);

  @override
  List<Object?> get props => [day, logs, goalMl];
}

final todayWaterProgressProvider = Provider<AsyncValue<TodayWaterProgress>>((
  ref,
) {
  final logs = ref.watch(todayWaterLogsProvider);
  final profile = ref.watch(userProfileProvider);
  if (logs.hasError && !logs.hasValue) {
    return AsyncError(logs.error!, logs.stackTrace ?? StackTrace.empty);
  }
  if (!logs.hasValue) return const AsyncLoading();
  return AsyncData(
    TodayWaterProgress(
      day: ref.watch(dashboardDayProvider),
      logs: logs.requireValue,
      goalMl: profile.value?.waterGoal ?? AppConstants.defaultWaterGoalMl,
    ),
  );
});

class WaterHistoryDay extends Equatable {
  const WaterHistoryDay({required this.date, required this.ml});

  final DateTime date;
  final int ml;

  @override
  List<Object?> get props => [date, ml];
}

final waterHistoryProvider = StreamProvider<List<WaterHistoryDay>>((ref) async* {
  final now = ref.watch(clockProvider)().startOfDay;
  final from = now.addDays(-6);
  yield* ref.watch(waterRepositoryProvider).watchRange(from, now).map((logs) {
    final byDay = <String, int>{};
    for (final log in logs) {
      byDay[log.dayKey] = (byDay[log.dayKey] ?? 0) + log.amountMl;
    }
    return [
      for (var i = 6; i >= 0; i--)
        WaterHistoryDay(
          date: from.addDays(i),
          ml: byDay[from.addDays(i).dayKey] ?? 0,
        ),
    ];
  });
});

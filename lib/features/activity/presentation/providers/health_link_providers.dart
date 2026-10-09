import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/services/health/health_data_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/datasources/health_activity_cache.dart';
import '../../data/repositories/activity_repository_impl.dart';
import '../../domain/models/daily_activity.dart';

enum HealthLinkOutcome { linked, denied, unavailable }

final class HealthLinkController {
  const HealthLinkController({
    required HealthDataService health,
    required HealthActivityCache cache,
    required void Function() onChanged,
  }) : _health = health,
       _cache = cache,
       _onChanged = onChanged;

  final HealthDataService _health;
  final HealthActivityCache _cache;
  final void Function() _onChanged;

  Future<HealthLinkOutcome> connect() async {
    try {
      if (!await _health.isAvailable()) return HealthLinkOutcome.unavailable;
      final existing = await _health.hasPermissions(healthActivityReadTypes);
      final granted =
          existing == true ||
          await _health.requestPermissions(healthActivityReadTypes);
      if (!granted) {
        await _cache.setLinked(value: false);
        _onChanged();
        return HealthLinkOutcome.denied;
      }
      await _cache.setLinked(value: true);
      _onChanged();
      return HealthLinkOutcome.linked;
    } on Object {
      return HealthLinkOutcome.unavailable;
    }
  }
}

final healthLinkControllerProvider = Provider<HealthLinkController>((ref) {
  return HealthLinkController(
    health: ref.watch(healthDataServiceProvider),
    cache: ref.watch(healthActivityCacheProvider),
    onChanged: () => ref.read(healthSyncEpochProvider.notifier).bump(),
  );
});

final healthLinkedProvider = Provider<bool>((ref) {
  ref.watch(healthSyncEpochProvider);
  return ref.watch(healthActivityCacheProvider).isLinked;
});

final weeklyActivityProvider = FutureProvider<List<DailyActivity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  final today = ref.watch(clockProvider)().startOfDay;
  final days = <DailyActivity>[];
  for (var i = 6; i >= 0; i--) {
    days.add(await repo.watchDay(today.addDays(-i)).first);
  }
  return days;
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/data/repositories/meal_plan_repository_impl.dart';
import '../../../water/data/repositories/water_repository_impl.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/services/notification_service.dart';

/// Plan, su ve profil değişince hatırlatmaları günceller.
/// Arayüz zamanlama yapmaz; yalnızca bu bağlayıcı servisi çağırır.
final notificationCoordinatorProvider = Provider<void>((ref) {
  ref.watch(currentUserIdProvider);
  final clock = ref.read(clockProvider);
  final now = clock();

  Future<void> sync() async {
    try {
      await ref.read(notificationServiceProvider).sync();
    } on Object {
      // Bildirim kurulamasa da uygulama çalışmaya devam eder.
    }
  }

  void schedule() => unawaited(sync());

  ref.listen(notificationSettingsProvider, (previous, next) {
    if (!next.hasValue || previous?.value == next.value) return;
    schedule();
  });

  ref.listen(userProfileProvider, (previous, next) {
    final before = previous?.value;
    final after = next.value;
    if (before?.waterGoal == after?.waterGoal &&
        before?.mealsPerDay == after?.mealsPerDay &&
        before?.breakfastPreference == after?.breakfastPreference &&
        before?.fastingPreference == after?.fastingPreference &&
        before?.eatingWindowStartMinutes == after?.eatingWindowStartMinutes) {
      return;
    }
    schedule();
  });

  final plans = ref
      .read(mealPlanRepositoryProvider)
      .watchWeek(now)
      .listen((_) => schedule());
  final water = ref
      .read(waterRepositoryProvider)
      .watchDay(now)
      .listen((_) => schedule());
  ref.onDispose(() {
    plans.cancel();
    water.cancel();
  });

  schedule();
});

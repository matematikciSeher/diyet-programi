import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../data/repositories/local_onboarding_repository.dart';

/// Onboarding'in bu cihazda tamamlanıp tamamlanmadığı.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingRepositoryProvider).isCompleted;

  Future<void> complete() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    await ref
        .read(analyticsServiceProvider)
        .logEvent(AnalyticsEvents.onboardingCompleted);
    state = true;
  }

  Future<void> reset() async {
    await ref.read(onboardingRepositoryProvider).reset();
    state = false;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

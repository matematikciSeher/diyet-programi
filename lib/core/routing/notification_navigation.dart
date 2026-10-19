import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/meals/presentation/providers/diary_providers.dart';
import '../../shared/models/enums.dart';
import '../../shared/services/service_providers.dart';
import '../utils/json_utils.dart';
import 'app_router.dart';
import 'app_routes.dart';

/// Bildirim yükünden çözülen hedef. Öğün ve su günlüğe, plan ekranına gider.
class NotificationTarget {
  const NotificationTarget({required this.location, this.meal, this.section});

  final String location;
  final MealType? meal;
  final String? section;
}

NotificationTarget? resolveNotificationTarget(String payload) {
  final uri = Uri.tryParse(payload);
  if (uri == null || uri.path.isEmpty) return null;
  MealType? meal;
  String? section;
  if (uri.path == AppRoutes.diary) {
    meal = JsonUtils.readEnumOrNull(
      MealType.values,
      uri.queryParameters[AppRoutes.mealQueryParam],
    );
    section = uri.queryParameters[AppRoutes.sectionQueryParam];
  }
  return NotificationTarget(
    location: payload.startsWith('/') ? payload : uri.path,
    meal: meal,
    section: section,
  );
}

/// Bildirim tıklamasını ilgili ekrana yönlendirir.
void handleNotificationPayload(ProviderContainer container, String payload) {
  final target = resolveNotificationTarget(payload);
  if (target == null) return;
  if (target.location.startsWith(AppRoutes.diary)) {
    final meals = container.read(diaryMealFilterProvider.notifier);
    if (target.meal != null) {
      meals.select(target.meal!);
    } else {
      meals.clear();
    }
    if (target.section != null) {
      container
          .read(diaryFocusProvider.notifier)
          .focus(DiaryFocus(section: target.section, meal: target.meal));
    }
  }
  container.read(appRouterProvider).go(target.location);
}

void attachNotificationNavigation(ProviderContainer container) {
  container.read(localNotificationServiceProvider).onNotificationTapped.listen((
    payload,
  ) {
    handleNotificationPayload(container, payload);
  });
}

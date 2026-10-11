import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/ai_coach/presentation/pages/ai_coach_page.dart';
import '../../features/authentication/presentation/pages/sign_in_page.dart';
import '../../features/barcode/presentation/pages/barcode_scanner_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/fasting/presentation/pages/fasting_page.dart';
import '../../features/food/presentation/pages/custom_food_page.dart';
import '../../features/food/presentation/pages/food_detail_page.dart';
import '../../features/food/presentation/pages/food_search_page.dart';
import '../../features/food/presentation/pages/recipe_builder_page.dart';
import '../../features/food/presentation/pages/photo_log_page.dart';
import '../../features/food/presentation/pages/voice_log_page.dart';
import '../../features/meal_plans/presentation/pages/meal_plans_page.dart';
import '../../features/meal_plans/presentation/pages/shopping_list_page.dart';
import '../../features/meals/presentation/pages/diary_page.dart';
import '../../features/measurements/presentation/pages/measurements_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/nutrition/presentation/pages/nutrition_plan_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../../features/profile/presentation/pages/personal_info_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/progress/presentation/pages/progress_page.dart';
import '../../features/recipes/presentation/pages/recipe_create_page.dart';
import '../../features/recipes/presentation/pages/recipe_detail_page.dart';
import '../../features/recipes/presentation/pages/recipes_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/subscription/domain/models/app_feature.dart';
import '../../features/subscription/presentation/pages/paywall_page.dart';
import '../../features/subscription/presentation/widgets/premium_gate.dart';
import '../../features/water/presentation/pages/water_page.dart';
import '../../features/weight/presentation/pages/weight_page.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/food.dart';
import '../../shared/services/service_providers.dart';
import '../utils/json_utils.dart';
import 'analytics_route_observer.dart';
import 'app_routes.dart';
import 'app_startup.dart';
import 'main_shell.dart';
import 'system_pages.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  // Açılış, oturum veya onboarding durumu değişince yönlendirme yeniden
  // değerlendirilir.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(appStartupProvider, (_, _) => refresh.value++)
    ..listen(authStateProvider, (_, _) => refresh.value++)
    ..listen(onboardingCompletedProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    observers: [AnalyticsRouteObserver(ref.read(analyticsServiceProvider))],
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      _route(AppRoutes.splash, (_) => const SplashPage()),
      _route(AppRoutes.onboarding, (_) => const OnboardingPage()),
      _route(AppRoutes.signIn, (_) => const SignInPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          _branch(AppRoutes.dashboard, (_) => const DashboardPage()),
          _branch(AppRoutes.diary, (_) => const DiaryPage()),
          _branch(
            AppRoutes.plans,
            (_) => const PremiumGate(
              feature: AppFeature.personalMealPlan,
              child: MealPlansPage(),
            ),
          ),
          _branch(AppRoutes.progress, (_) => const ProgressPage()),
          _branch(AppRoutes.profile, (_) => const ProfilePage()),
        ],
      ),
      _premiumRoute(
        AppRoutes.nutritionPlan,
        AppFeature.personalMealPlan,
        const NutritionPlanPage(),
      ),
      _stateRoute(
        AppRoutes.foodSearch,
        (state) => FoodSearchPage(
          initialMeal: _mealParam(state),
          logDate: _dateParam(state),
        ),
      ),
      _stateRoute(
        AppRoutes.foodDetail,
        (state) => FoodDetailPage(
          foodId: state.pathParameters['id'] ?? '',
          initialFood: state.extra is Food ? state.extra! as Food : null,
          initialMeal: _mealParam(state),
          logDate: _dateParam(state),
        ),
      ),
      _stateRoute(
        AppRoutes.customFood,
        (state) => CustomFoodPage(
          meal: _mealParam(state),
          barcode: state.uri.queryParameters[AppRoutes.barcodeQueryParam],
          logDate: _dateParam(state),
        ),
      ),
      _stateRoute(
        AppRoutes.recipeBuilder,
        (state) => RecipeBuilderPage(
          meal: _mealParam(state),
          logDate: _dateParam(state),
        ),
      ),
      _stateRoute(
        AppRoutes.barcodeScanner,
        (state) => BarcodeScannerPage(
          meal: _mealParam(state),
          logDate: _dateParam(state),
        ),
      ),
      GoRoute(
        path: AppRoutes.photoLog,
        name: AppRoutes.photoLog,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PremiumGate(
          feature: AppFeature.photoFoodAnalysis,
          child: PhotoLogPage(
            initialMeal: _mealParam(state),
            logDate: _dateParam(state),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.voiceLog,
        name: AppRoutes.voiceLog,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => VoiceLogPage(
          initialMeal: _mealParam(state),
          logDate: _dateParam(state),
        ),
      ),
      _route(AppRoutes.recipes, (_) => const RecipesPage()),
      _route(AppRoutes.recipeCreate, (_) => const RecipeCreatePage()),
      _stateRoute(
        AppRoutes.recipeDetail,
        (state) => RecipeDetailPage(recipeId: state.pathParameters['id'] ?? ''),
      ),
      _premiumRoute(
        AppRoutes.shoppingList,
        AppFeature.autoShoppingList,
        const ShoppingListPage(),
      ),
      _route(AppRoutes.water, (_) => const WaterPage()),
      _route(AppRoutes.weight, (_) => const WeightPage()),
      _route(AppRoutes.measurements, (_) => const MeasurementsPage()),
      _route(AppRoutes.fasting, (_) => const FastingPage()),
      _route(AppRoutes.activity, (_) => const ActivityPage()),
      _route(AppRoutes.notifications, (_) => const NotificationsPage()),
      _route(AppRoutes.personalInfo, (_) => const PersonalInfoPage()),
      _premiumRoute(AppRoutes.aiCoach, AppFeature.aiCoach, const AiCoachPage()),
      _stateRoute(
        AppRoutes.paywall,
        (state) => PaywallPage(
          source: JsonUtils.readEnumOrNull(
            AppFeature.values,
            state.uri.queryParameters[AppRoutes.featureQueryParam],
          ),
        ),
      ),
      _route(AppRoutes.settings, (_) => const SettingsPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;
  final auth = ref.read(authStateProvider);
  final startup = ref.read(appStartupProvider);

  if (startup.isLoading || (auth.isLoading && !auth.hasValue)) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (!ref.read(onboardingCompletedProvider)) {
    return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
  }

  if (auth.value == null) {
    return location == AppRoutes.signIn ? null : AppRoutes.signIn;
  }

  if (AppRoutes.publicRoutes.contains(location)) return AppRoutes.dashboard;
  return null;
}

GoRoute _route(String path, WidgetBuilder builder) => GoRoute(
  path: path,
  name: path,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => builder(context),
);

GoRoute _premiumRoute(String path, AppFeature feature, Widget page) =>
    _route(path, (_) => PremiumGate(feature: feature, child: page));

GoRoute _stateRoute(String path, Widget Function(GoRouterState) builder) =>
    GoRoute(
      path: path,
      name: path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => builder(state),
    );

MealType? _mealParam(GoRouterState state) => JsonUtils.readEnumOrNull(
  MealType.values,
  state.uri.queryParameters[AppRoutes.mealQueryParam],
);

DateTime? _dateParam(GoRouterState state) =>
    JsonUtils.readDate(state.uri.queryParameters[AppRoutes.dateQueryParam]);

StatefulShellBranch _branch(String path, WidgetBuilder builder) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          name: path,
          builder: (context, state) => builder(context),
        ),
      ],
    );

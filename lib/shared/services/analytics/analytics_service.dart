import '../../../core/utils/app_logger.dart';

/// Ürün analitiği. Hedef: `FirebaseAnalyticsService`.
/// Olay isimleri [AnalyticsEvents] içinde merkezi olarak tutulur.
abstract interface class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
  Future<void> logScreenView(String screenName);
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
  Future<void> setCollectionEnabled({required bool enabled});
}

abstract final class AnalyticsEvents {
  static const appOpen = 'app_open';
  static const onboardingCompleted = 'onboarding_completed';
  static const signUp = 'sign_up';
  static const login = 'login';
  static const foodAdded = 'food_added';
  static const foodSearch = 'food_search';
  static const foodSelected = 'food_selected';
  static const barcodeScan = 'barcode_scan';
  static const barcodeProductFound = 'barcode_product_found';
  static const barcodeProductNotFound = 'barcode_product_not_found';
  static const customFoodCreated = 'custom_food_created';
  static const foodFavorited = 'food_favorited';
  static const mealLogged = 'meal_logged';
  static const waterLogged = 'water_logged';
  static const weightLogged = 'weight_logged';
  static const mealPlanCreated = 'meal_plan_created';
  static const recipeOpened = 'recipe_opened';
  static const fastingStarted = 'fasting_started';
  static const subscriptionScreenOpened = 'subscription_screen_opened';
  static const paywallViewed = 'paywall_viewed';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseRestored = 'purchase_restored';
  static const premiumGateShown = 'premium_gate_shown';
}

/// Geliştirmede olayları yalnızca log'a yazar.
class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async =>
      AppLogger.debug('[analytics] $name ${parameters ?? ''}');

  @override
  Future<void> logScreenView(String screenName) async =>
      AppLogger.debug('[analytics] screen_view $screenName');

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setCollectionEnabled({required bool enabled}) async {}
}

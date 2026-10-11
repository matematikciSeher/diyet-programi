import '../../../../shared/services/subscription/subscription_service.dart';

/// Uygulamadaki özelliklerin ücretsiz / premium kataloğu.
///
/// Erişim kararı yalnızca [requiredEntitlement] üzerinden verilir; RevenueCat
/// panelinde tanımlı entitlement'larla birebir eşleşir. İleride farklı
/// paketler (ör. "pro_coach") gerekirse sadece bu eşleme değişir.
enum AppFeature {
  // Ücretsiz
  calorieTracking,
  weightTracking,
  waterTracking,
  foodLogging,
  basicProgress,
  fasting,

  // Premium
  personalMealPlan(Entitlements.premium),
  aiCoach(Entitlements.premium),
  photoFoodAnalysis(Entitlements.premium),
  advancedAnalytics(Entitlements.premium),
  advancedRecipes(Entitlements.premium),
  autoShoppingList(Entitlements.premium),
  advancedGoals(Entitlements.premium),
  advancedReports(Entitlements.premium),
  adFree(Entitlements.premium),
  periodicReports(Entitlements.premium);

  const AppFeature([this.requiredEntitlement]);

  /// `null` ise özellik herkese açıktır.
  final String? requiredEntitlement;

  bool get isPremium => requiredEntitlement != null;

  static List<AppFeature> get premiumFeatures =>
      values.where((f) => f.isPremium).toList(growable: false);

  /// Premium sayfasında anlatılan paket. Diğer kilitli özellikler
  /// bu listeye eklenmez.
  static const packageBenefits = <AppFeature>[
    aiCoach,
    personalMealPlan,
    adFree,
  ];
}

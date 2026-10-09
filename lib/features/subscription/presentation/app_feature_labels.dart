import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/services/subscription/subscription_service.dart';
import '../domain/models/app_feature.dart';

extension AppFeatureL10n on AppFeature {
  String label(AppLocalizations l10n) => switch (this) {
    AppFeature.calorieTracking => l10n.appFeatureCalorieTracking,
    AppFeature.weightTracking => l10n.appFeatureWeightTracking,
    AppFeature.waterTracking => l10n.appFeatureWaterTracking,
    AppFeature.foodLogging => l10n.appFeatureFoodLogging,
    AppFeature.basicProgress => l10n.appFeatureBasicProgress,
    AppFeature.personalMealPlan => l10n.appFeaturePersonalMealPlan,
    AppFeature.aiCoach => l10n.appFeatureAiCoach,
    AppFeature.photoFoodAnalysis => l10n.appFeaturePhotoFoodAnalysis,
    AppFeature.advancedAnalytics => l10n.appFeatureAdvancedAnalytics,
    AppFeature.advancedRecipes => l10n.appFeatureAdvancedRecipes,
    AppFeature.autoShoppingList => l10n.appFeatureAutoShoppingList,
    AppFeature.advancedGoals => l10n.appFeatureAdvancedGoals,
    AppFeature.advancedReports => l10n.appFeatureAdvancedReports,
    AppFeature.adFree => l10n.appFeatureAdFree,
    AppFeature.fasting => l10n.appFeatureFasting,
    AppFeature.periodicReports => l10n.appFeaturePeriodicReports,
  };

  /// Paywall ve kilit ekranlarında gösterilen fayda cümlesi.
  String? description(AppLocalizations l10n) => switch (this) {
    AppFeature.personalMealPlan => l10n.appFeaturePersonalMealPlanDesc,
    AppFeature.aiCoach => l10n.appFeatureAiCoachDesc,
    AppFeature.photoFoodAnalysis => l10n.appFeaturePhotoFoodAnalysisDesc,
    AppFeature.advancedAnalytics => l10n.appFeatureAdvancedAnalyticsDesc,
    AppFeature.advancedRecipes => l10n.appFeatureAdvancedRecipesDesc,
    AppFeature.autoShoppingList => l10n.appFeatureAutoShoppingListDesc,
    AppFeature.advancedGoals => l10n.appFeatureAdvancedGoalsDesc,
    AppFeature.advancedReports => l10n.appFeatureAdvancedReportsDesc,
    AppFeature.adFree => l10n.appFeatureAdFreeDesc,
    AppFeature.fasting => l10n.appFeatureFastingDesc,
    AppFeature.periodicReports => l10n.appFeaturePeriodicReportsDesc,
    AppFeature.calorieTracking ||
    AppFeature.weightTracking ||
    AppFeature.waterTracking ||
    AppFeature.foodLogging ||
    AppFeature.basicProgress => null,
  };

  IconData get icon => switch (this) {
    AppFeature.calorieTracking => Icons.local_fire_department_outlined,
    AppFeature.weightTracking => Icons.monitor_weight_outlined,
    AppFeature.waterTracking => Icons.water_drop_outlined,
    AppFeature.foodLogging => Icons.restaurant_outlined,
    AppFeature.basicProgress => Icons.show_chart_rounded,
    AppFeature.personalMealPlan => Icons.restaurant_menu_rounded,
    AppFeature.aiCoach => Icons.auto_awesome_outlined,
    AppFeature.photoFoodAnalysis => Icons.photo_camera_outlined,
    AppFeature.advancedAnalytics => Icons.insights_rounded,
    AppFeature.advancedRecipes => Icons.soup_kitchen_outlined,
    AppFeature.autoShoppingList => Icons.shopping_basket_outlined,
    AppFeature.advancedGoals => Icons.track_changes_rounded,
    AppFeature.advancedReports => Icons.assessment_outlined,
    AppFeature.adFree => Icons.block_rounded,
    AppFeature.fasting => Icons.timer_outlined,
    AppFeature.periodicReports => Icons.calendar_month_outlined,
  };
}

extension SubscriptionPeriodL10n on SubscriptionPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    SubscriptionPeriod.weekly => l10n.paywallPeriodWeekly,
    SubscriptionPeriod.monthly => l10n.paywallPeriodMonthly,
    SubscriptionPeriod.annual => l10n.paywallPeriodAnnual,
    SubscriptionPeriod.lifetime => l10n.paywallPeriodLifetime,
  };
}

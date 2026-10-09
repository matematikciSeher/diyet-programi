import '../../../../core/config/app_config.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/ai/ai_nutrition_service.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import 'assistant_limits.dart';
import 'nutrition_assistant_service.dart';
import 'proxy_nutrition_assistant_service.dart';
import 'unconfigured_nutrition_assistant_service.dart';

/// Debug/test sahte asistanı release ve yapılandırılmamış üretimden ayırır.
NutritionAssistantService selectNutritionAssistantService({
  required AppConfig config,
  required NutritionAssistantService fake,
  required AiNutritionService ai,
  required Future<List<Recipe>> Function(UserProfile? profile) loadRecipes,
  required Future<List<PlannedMeal>> Function(DateTime day) loadWeek,
}) {
  if (config.useFakeServices) return fake;
  if (!config.isAiProxyConfigured) {
    return const UnconfiguredNutritionAssistantService();
  }
  return ProxyNutritionAssistantService(
    ai: ai,
    loadRecipes: loadRecipes,
    loadWeek: loadWeek,
    limits: AssistantLimits.fromConfig(config),
  );
}

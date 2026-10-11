import '../../../../core/config/app_config.dart';
import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/ai/ai_nutrition_service.dart';
import '../../../meal_plans/domain/models/planned_meal.dart';
import 'assistant_limits.dart';
import 'nutrition_assistant_service.dart';
import 'proxy_nutrition_assistant_service.dart';

/// Yerel kural asistanı, sahte servislerde ve henüz proxy yapılandırılmamış
/// sürümde kullanılır. Gerçek proxy adresi varsa ve sahte servisler kapalıysa
/// istek mevcut proxy uygulamasına gider.
NutritionAssistantService selectNutritionAssistantService({
  required AppConfig config,
  required NutritionAssistantService fake,
  required AiNutritionService ai,
  required Future<List<Recipe>> Function(UserProfile? profile) loadRecipes,
  required Future<List<PlannedMeal>> Function(DateTime day) loadWeek,
}) {
  if (config.useFakeServices || !config.isAiProxyConfigured) return fake;
  return ProxyNutritionAssistantService(
    ai: ai,
    loadRecipes: loadRecipes,
    loadWeek: loadWeek,
    limits: AssistantLimits.fromConfig(config),
  );
}

import '../../../../shared/models/recipe.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../recipes/domain/services/recipe_recommendation_service.dart';
import '../models/assistant_grounded_facts.dart';
import '../models/assistant_reply.dart';
import 'assistant_response_parser.dart';

/// Model çıktısını katalog, alerji ve sayı kayıtlarıyla sınırlar.
///
/// Yazma eylemi kabul edilmez. Var olmayan tarif kimliği düşer.
class AssistantResponseGuard {
  const AssistantResponseGuard({
    RecipeRecommendationService? recommender,
  }) : _recommender = recommender ?? const RecipeRecommendationService();

  static const allowedActionTypes = {
    'recommend_recipe',
    'open_plan',
    'open_diary',
    'open_recipes',
    'open_weight',
    'open_fasting',
  };

  static const _unsafePhrases = [
    'alerjin olsa da',
    'alerjine rağmen',
    'alerjine ragmen',
    'az miktarda tüket',
    'az miktarda tuket',
    'biraz yiyebilirsin',
    'ignore your allergy',
    'despite your allergy',
    'small amount is fine',
  ];

  final RecipeRecommendationService _recommender;

  InterpretedReply apply({
    required ParsedAssistantResponse parsed,
    required AssistantGroundedFacts facts,
    required List<Recipe> allowedRecipes,
    required UserProfile? profile,
  }) {
    final byId = {for (final recipe in allowedRecipes) recipe.id: recipe};
    final recipes = <AssistantRecipeRef>[];
    final actions = <AssistantAction>{};
    for (final action in parsed.actions) {
      if (!allowedActionTypes.contains(action.type)) continue;
      switch (action.type) {
        case 'recommend_recipe':
          final recipe = byId[action.recipeId];
          if (recipe == null) continue;
          if (profile != null && !_recommender.isSuitable(recipe, profile)) {
            continue;
          }
          if (recipes.any((item) => item.id == recipe.id)) continue;
          recipes.add(
            AssistantRecipeRef(
              id: recipe.id,
              title: recipe.title,
              calories: recipe.calories,
              proteinG: recipe.protein,
            ),
          );
          actions.add(AssistantAction.openRecipes);
        case 'open_plan':
          actions.add(AssistantAction.openPlan);
        case 'open_diary':
          actions.add(AssistantAction.openDiary);
        case 'open_recipes':
          actions.add(AssistantAction.openRecipes);
        case 'open_weight':
          actions.add(AssistantAction.openWeight);
        case 'open_fasting':
          actions.add(AssistantAction.openFasting);
      }
    }
    if (facts.showPlan) actions.add(AssistantAction.openPlan);
    final unsafe = _unsafe(parsed.text);
    final contradicts = _contradicts(parsed.text, facts);
    final commentary = unsafe || contradicts || parsed.text.isEmpty
        ? null
        : _clip(parsed.text);
    return InterpretedReply(
      facts: facts,
      recipes: recipes,
      commentary: commentary,
      commentarySuppressed: unsafe,
      actions: actions.toList(),
    );
  }

  bool _unsafe(String text) {
    final normalized = text
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
    return _unsafePhrases.any(normalized.contains);
  }

  bool _contradicts(String text, AssistantGroundedFacts facts) {
    final lower = text.toLowerCase();
    final statesKcal = RegExp(r'\d{2,5}\s*(kcal|kalori)').hasMatch(lower);
    final statesWater = RegExp(r'\d{2,5}\s*ml').hasMatch(lower);
    final statesSteps = RegExp(r'\d{2,6}\s*ad[ıi]m').hasMatch(lower);
    if (statesKcal && (!facts.showCalories || facts.consumedCalories == null)) {
      return true;
    }
    if (statesWater && (!facts.showWater || facts.waterMl == null)) return true;
    if (statesSteps && (!facts.showActivity || !facts.stepsKnown)) return true;
    if (facts.showCalories &&
        facts.consumedCalories != null &&
        facts.calorieTarget != null) {
      final allowed = {
        facts.consumedCalories!.round(),
        facts.calorieTarget!.round(),
        (facts.calorieTarget! - facts.consumedCalories!).round().abs(),
      };
      for (final match in RegExp(r'(\d{2,5})\s*(kcal|kalori)').allMatches(text.toLowerCase())) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && !allowed.contains(value)) return true;
      }
    }
    if (facts.showWater && facts.waterMl != null) {
      for (final match in RegExp(r'(\d{2,5})\s*ml').allMatches(text.toLowerCase())) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value != facts.waterMl && value != facts.waterGoalMl) {
          return true;
        }
      }
    }
    if (facts.showActivity && facts.stepsKnown && facts.steps != null) {
      for (final match in RegExp(r'(\d{2,6})\s*ad[ıi]m').allMatches(text.toLowerCase())) {
        final value = int.tryParse(match.group(1)!);
        if (value != null && value != facts.steps) return true;
      }
    }
    return false;
  }

  String _clip(String text) => text.length <= 1200 ? text : text.substring(0, 1200);
}

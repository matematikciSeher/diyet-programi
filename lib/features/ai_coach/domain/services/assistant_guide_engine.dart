import '../catalog/assistant_catalog.dart';
import '../models/assistant_context.dart';
import '../models/assistant_grounded_facts.dart';
import '../models/assistant_reply.dart';
import '../models/guide_snapshot.dart';
import 'assistant_calendar.dart';
import 'assistant_safety.dart';
import '../../../../shared/models/enums.dart';

/// Katalog sorularını kayıtlı verilere ve sabit rehber metnine bağlar.
///
/// Sayı uydurmaz, tarif adı icat etmez, planı ve alışveriş listesini değiştirmez.
class AssistantGuideEngine {
  const AssistantGuideEngine();

  static const planSeparator = '\u001f';

  GuideReply reply(AssistantQuestion question, AssistantContext context) {
    return GuideReply(
      questionId: question.id,
      snapshot: _snapshot(question, context),
      recipes: question.data == GuideDataKind.recipes
          ? _recipeRefs(context)
          : const [],
      disclaimer: _disclaimer(question),
      actions: _actions(question),
    );
  }

  bool _disclaimer(AssistantQuestion question) {
    final category = AssistantCatalog.categoryOf(question.id);
    if (category == null) return true;
    if (category.section == AssistantSection.wellness) return true;
    return category.id == 'facts' ||
        category.id == 'weight' ||
        category.id == 'preferences' ||
        category.id == 'swaps';
  }

  List<AssistantAction> _actions(AssistantQuestion question) {
    final fromData = switch (question.data) {
      GuideDataKind.daily || GuideDataKind.calories || GuideDataKind.week =>
        AssistantAction.openDiary,
      GuideDataKind.water => AssistantAction.openWater,
      GuideDataKind.recipes || GuideDataKind.preferences =>
        AssistantAction.openRecipes,
      GuideDataKind.plan => AssistantAction.openPlan,
      GuideDataKind.shopping => AssistantAction.openShopping,
      GuideDataKind.weight => AssistantAction.openWeight,
      GuideDataKind.none => null,
    };
    if (fromData != null) return [fromData];
    return switch (AssistantCatalog.categoryOf(question.id)?.id) {
      'recipes' || 'breakfast' || 'main_meals' || 'snacks' => [
        AssistantAction.openRecipes,
      ],
      'planning' => [AssistantAction.openPlan],
      'shopping' => [AssistantAction.openShopping],
      'water' => [AssistantAction.openWater],
      'weight' => [AssistantAction.openWeight],
      _ => const [],
    };
  }

  GuideSnapshot _snapshot(AssistantQuestion question, AssistantContext context) {
    return switch (question.data) {
      GuideDataKind.none => const GuideSnapshot(),
      GuideDataKind.daily => _daily(context),
      GuideDataKind.calories => _calories(context),
      GuideDataKind.water => _water(context),
      GuideDataKind.week => _week(question, context),
      GuideDataKind.recipes => _recipes(context),
      GuideDataKind.preferences => _preferences(context),
      GuideDataKind.plan => _plan(context),
      GuideDataKind.shopping => _shopping(context),
      GuideDataKind.weight => _weight(context),
    };
  }

  GuideSnapshot _calories(AssistantContext context) {
    if (context.todayMeals.isEmpty) {
      return const GuideSnapshot(
        kind: GuideDataKind.calories,
        recordsMissing: true,
      );
    }
    final personal = context.hasPersonalTargets;
    final target = personal ? context.targets.calories : null;
    return GuideSnapshot(
      kind: GuideDataKind.calories,
      personalTarget: personal,
      consumedCalories: context.consumed.calories,
      targetCalories: target,
      mealCount: context.todayMeals.length,
      targetBelowSafeFloor:
          target != null &&
          target > 0 &&
          target < AssistantSafety.minSafeDailyKcal,
    );
  }

  GuideSnapshot _daily(AssistantContext context) {
    if (context.todayMeals.isEmpty) {
      return const GuideSnapshot(
        kind: GuideDataKind.daily,
        recordsMissing: true,
      );
    }
    final base = _calories(context);
    final logged = context.loggedMealTypes;
    final tags = {for (final meal in context.todayMeals) ...meal.tags};
    final macros = context.todayMeals.any(
      (meal) =>
          meal.nutrition.proteinG > 0 ||
          meal.nutrition.carbsG > 0 ||
          meal.nutrition.fatG > 0,
    );
    return GuideSnapshot(
      kind: GuideDataKind.daily,
      personalTarget: base.personalTarget,
      consumedCalories: base.consumedCalories,
      targetCalories: base.targetCalories,
      mealCount: base.mealCount,
      targetBelowSafeFloor: base.targetBelowSafeFloor,
      loggedMealTypes: [
        for (final type in MealType.values)
          if (logged.contains(type)) type.name,
      ],
      missingMealTypes: [
        for (final type in MealType.values)
          if (!logged.contains(type)) type.name,
      ],
      foodTagsKnown: tags.isNotEmpty,
      presentFoodTags: [for (final tag in FoodTag.values) if (tags.contains(tag)) tag.name],
      macrosRecorded: macros,
      proteinG: macros ? context.consumed.proteinG : null,
      proteinTargetG: base.personalTarget ? context.targets.proteinG : null,
      carbsG: macros ? context.consumed.carbsG : null,
      carbsTargetG: base.personalTarget ? context.targets.carbsG : null,
      fatG: macros ? context.consumed.fatG : null,
      fatTargetG: base.personalTarget ? context.targets.fatG : null,
    );
  }

  GuideSnapshot _water(AssistantContext context) {
    if (context.todayWaterLogCount <= 0) {
      return const GuideSnapshot(kind: GuideDataKind.water, recordsMissing: true);
    }
    return GuideSnapshot(
      kind: GuideDataKind.water,
      waterKnown: true,
      waterMl: context.todayWaterMl,
      waterGoalMl: _waterGoal(context),
    );
  }

  int? _waterGoal(AssistantContext context) {
    final goal = context.profile?.waterGoal;
    if (goal != null && goal > 0) return goal;
    if (context.hasPersonalTargets) return context.targets.waterMl;
    return null;
  }

  GuideSnapshot _week(AssistantQuestion question, AssistantContext context) {
    final calories = <String, double>{};
    for (final meal in context.weekMeals) {
      if (!AssistantCalendar.dayKeyInOpenWeek(meal.dayKey, context.now)) {
        continue;
      }
      calories[meal.dayKey] =
          (calories[meal.dayKey] ?? 0) + meal.nutrition.calories;
    }
    final water = <String, int>{};
    for (final log in context.weekWaterLogs) {
      if (!AssistantCalendar.dayKeyInOpenWeek(log.dayKey, context.now)) {
        continue;
      }
      water[log.dayKey] = (water[log.dayKey] ?? 0) + log.amountMl;
    }
    final mealKeys = calories.keys.toList()..sort();
    final waterKeys = water.keys.toList()..sort();
    final personal = context.hasPersonalTargets;
    final aboutWater = question.id == 'week.water';
    return GuideSnapshot(
      kind: GuideDataKind.week,
      recordsMissing: aboutWater ? waterKeys.isEmpty : mealKeys.isEmpty,
      personalTarget: personal,
      targetCalories: personal ? context.targets.calories : null,
      elapsedDays: context.now.weekday,
      mealDays: [
        for (final key in mealKeys)
          GuideDayAmount(dayKey: key, amount: calories[key]!),
      ],
      waterDays: [
        for (final key in waterKeys)
          GuideDayAmount(dayKey: key, amount: water[key]!.toDouble()),
      ],
      waterGoalMl: _waterGoal(context),
    );
  }

  GuideSnapshot _recipes(AssistantContext context) {
    final suitable = _suitable(context);
    return GuideSnapshot(
      kind: GuideDataKind.recipes,
      recordsMissing: context.knownRecipes.isEmpty || suitable.isEmpty,
      recipeCatalogCount: context.knownRecipes.length,
      recipeMatchCount: suitable.length,
      preferencesKnown: _hasPreferences(context),
      allergies: context.profile?.allergies ?? const [],
      dislikes: context.profile?.dislikedFoods ?? const [],
      dietTypeName: context.profile?.dietType?.name,
    );
  }

  List<AssistantKnownRecipe> _suitable(AssistantContext context) => [
    for (final recipe in context.knownRecipes)
      if (recipe.suitable && recipe.title.trim().isNotEmpty && recipe.id.isNotEmpty)
        recipe,
  ];

  List<AssistantRecipeRef> _recipeRefs(AssistantContext context) => [
    for (final recipe in _suitable(context).take(5))
      AssistantRecipeRef(
        id: recipe.id,
        title: recipe.title,
        calories: recipe.calories,
        proteinG: recipe.proteinG,
      ),
  ];

  GuideSnapshot _preferences(AssistantContext context) {
    final known = _hasPreferences(context);
    return GuideSnapshot(
      kind: GuideDataKind.preferences,
      recordsMissing: !known,
      preferencesKnown: known,
      allergies: context.profile?.allergies ?? const [],
      dislikes: context.profile?.dislikedFoods ?? const [],
      dietTypeName: context.profile?.dietType?.name,
    );
  }

  bool _hasPreferences(AssistantContext context) {
    final profile = context.profile;
    if (profile == null) return false;
    return profile.allergies.isNotEmpty ||
        profile.dislikedFoods.isNotEmpty ||
        profile.dietType != null;
  }

  GuideSnapshot _plan(AssistantContext context) {
    final seen = <String>{};
    final lines = <String>[];
    for (final meal in [...context.weekPlan, ...context.todayPlan]) {
      if (meal.title.trim().isEmpty || !seen.add(meal.id)) continue;
      lines.add(
        [
          meal.dayKey,
          meal.mealType.name,
          meal.title,
          meal.nutrition.calories.toString(),
        ].join(planSeparator),
      );
    }
    return GuideSnapshot(
      kind: GuideDataKind.plan,
      recordsMissing: lines.isEmpty,
      planLines: lines,
    );
  }

  GuideSnapshot _shopping(AssistantContext context) {
    final preserved = [
      for (final line in context.shoppingLines)
        if (line.manual && line.name.trim().isNotEmpty) line.name.trim(),
    ];
    final fromPlan = context.shoppingLines.where((line) => !line.manual).length;
    return GuideSnapshot(
      kind: GuideDataKind.shopping,
      recordsMissing: context.shoppingLines.isEmpty,
      shoppingManual: preserved.length,
      shoppingFromPlan: fromPlan,
      shoppingManualNames: preserved.take(8).toList(),
    );
  }

  GuideSnapshot _weight(AssistantContext context) {
    final current =
        context.weights.firstOrNull?.weightKg ?? context.profile?.weight;
    if (current == null) {
      return const GuideSnapshot(kind: GuideDataKind.weight, recordsMissing: true);
    }
    return GuideSnapshot(
      kind: GuideDataKind.weight,
      weightKg: current,
      startWeightKg: context.profile?.effectiveStartWeight,
      targetWeightKg: context.profile?.targetWeight,
    );
  }
}

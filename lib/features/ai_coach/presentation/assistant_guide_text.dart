import 'package:flutter/widgets.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../../progress/presentation/progress_labels.dart';
import '../domain/content/assistant_guide_library.dart';
import '../domain/models/assistant_reply.dart';
import '../domain/models/guide_snapshot.dart';
import '../domain/services/assistant_calendar.dart';
import '../domain/services/assistant_guide_engine.dart';

/// Rehber yanıtını kısa cevap, maddeler, kayıt özeti ve öneri olarak yazar.
abstract final class AssistantGuideText {
  static String of(BuildContext context, GuideReply reply) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final copy = AssistantGuideLibrary.of(reply.questionId)?.forLanguage(language);
    final lines = <String>[];
    if (copy == null) {
      lines.add(l10n.assistantGuideBoundary);
    } else {
      lines.add(copy.direct);
      lines.addAll(copy.points.map((point) => '• $point'));
    }
    final data = _data(context, reply);
    if (data.isNotEmpty) {
      lines.add(l10n.assistantDataHeading);
      lines.add(data);
    }
    if (copy != null && copy.tips.isNotEmpty) {
      lines.add(l10n.assistantGuideTips);
      lines.addAll(copy.tips.map((tip) => '• $tip'));
    }
    if (reply.disclaimer) lines.add(l10n.assistantGuideDisclaimer);
    return lines.join('\n');
  }

  static String _data(BuildContext context, GuideReply reply) {
    final snapshot = reply.snapshot;
    return switch (snapshot.kind) {
      GuideDataKind.none => '',
      GuideDataKind.daily => _daily(context, snapshot),
      GuideDataKind.calories => _calories(context, snapshot),
      GuideDataKind.water => _water(context, snapshot),
      GuideDataKind.week => _week(context, reply),
      GuideDataKind.recipes => _recipes(context, reply),
      GuideDataKind.preferences => _preferences(context, snapshot),
      GuideDataKind.plan => _plan(context, snapshot),
      GuideDataKind.shopping => _shopping(context, snapshot),
      GuideDataKind.weight => _weight(context, snapshot),
    };
  }

  static String _calories(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (snapshot.recordsMissing || snapshot.consumedCalories == null) {
      return l10n.assistantGuideMissingMeals;
    }
    final consumed = _kcal(context, snapshot.consumedCalories!);
    final lines = <String>[];
    final target = snapshot.targetCalories;
    if (snapshot.personalTarget && target != null) {
      final gap = target - snapshot.consumedCalories!;
      lines.add(
        gap >= 0
            ? l10n.assistantRemainingCalories(consumed, _kcal(context, target), _kcal(context, gap))
            : l10n.assistantOverCaloriesInfo(consumed, _kcal(context, target), _kcal(context, -gap)),
      );
      if (snapshot.targetBelowSafeFloor) lines.add(l10n.assistantDailyTargetLow);
    } else {
      lines.add(l10n.assistantSummaryNoTarget(consumed));
    }
    return lines.join('\n');
  }

  static String _daily(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (snapshot.recordsMissing) return l10n.assistantGuideMissingMeals;
    final lines = <String>[_calories(context, snapshot)];
    if (snapshot.loggedMealTypes.isNotEmpty || snapshot.missingMealTypes.isNotEmpty) {
      lines.add(
        l10n.assistantGuideMealCoverage(
          _meals(context, snapshot.loggedMealTypes),
          _meals(context, snapshot.missingMealTypes),
        ),
      );
    }
    if (!snapshot.foodTagsKnown) {
      lines.add(l10n.assistantGuideTagsMissing);
    } else {
      lines.add(l10n.assistantGuideTags(_tags(context, snapshot.presentFoodTags)));
    }
    if (!snapshot.macrosRecorded) {
      lines.add(l10n.assistantMissingMacros);
    } else if (snapshot.personalTarget) {
      lines.add(_macro(context, l10n.macroProtein, snapshot.proteinG, snapshot.proteinTargetG));
      lines.add(_macro(context, l10n.macroCarbs, snapshot.carbsG, snapshot.carbsTargetG));
      lines.add(_macro(context, l10n.macroFat, snapshot.fatG, snapshot.fatTargetG));
    }
    return lines.where((line) => line.isNotEmpty).join('\n');
  }

  static String _macro(BuildContext context, String name, double? consumed, double? target) {
    if (consumed == null || target == null) return '';
    return context.l10n.assistantMacroLine(
      name,
      AppFormat.integer(context, consumed),
      AppFormat.integer(context, target),
    );
  }

  static String _water(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (!snapshot.waterKnown || snapshot.waterMl == null) {
      return l10n.assistantGuideWaterMissing;
    }
    final amount = AppFormat.liters(context, snapshot.waterMl!);
    final goal = snapshot.waterGoalMl;
    if (goal == null) return l10n.assistantWaterOnly(amount);
    if (snapshot.waterMl! >= goal) return l10n.assistantWaterReached(amount);
    return l10n.assistantWaterRemaining(
      amount,
      AppFormat.liters(context, goal),
      AppFormat.liters(context, goal - snapshot.waterMl!),
    );
  }

  static String _week(BuildContext context, GuideReply reply) {
    final l10n = context.l10n;
    final snapshot = reply.snapshot;
    final lines = <String>[
      l10n.assistantGuideWeekIntro(snapshot.elapsedDays, snapshot.mealDays.length),
    ];
    if (snapshot.mealDays.isEmpty) {
      lines.add(l10n.assistantGuideWeekNoMeals);
    } else {
      for (final day in snapshot.mealDays) {
        final label = _day(context, day.dayKey);
        final kcal = _kcal(context, day.amount);
        final target = snapshot.targetCalories;
        lines.add(
          snapshot.personalTarget && target != null
              ? l10n.assistantGuideWeekDayTarget(label, kcal, _kcal(context, target))
              : l10n.assistantGuideWeekDay(label, kcal),
        );
      }
    }
    if (snapshot.waterDays.isEmpty) {
      lines.add(l10n.assistantGuideWeekWaterNone);
    } else {
      final total = snapshot.waterDays.fold<int>(0, (sum, day) => sum + day.amount.round());
      lines.add(
        l10n.assistantGuideWeekWater(
          snapshot.waterDays.length,
          AppFormat.liters(context, total),
        ),
      );
    }
    lines.add(l10n.assistantGuideWeekNote);
    return lines.join('\n');
  }

  static String _recipes(BuildContext context, GuideReply reply) {
    final l10n = context.l10n;
    final snapshot = reply.snapshot;
    if (snapshot.recipeCatalogCount == 0) return l10n.assistantGuideRecipesEmpty;
    if (snapshot.recipeMatchCount == 0 || reply.recipes.isEmpty) {
      return l10n.assistantGuideRecipesNone;
    }
    final lines = <String>[
      l10n.assistantGuideRecipesIntro,
      for (final recipe in reply.recipes)
        '• ${l10n.assistantRecipeLine(recipe.title, _kcal(context, recipe.calories), _kcal(context, recipe.proteinG))}',
    ];
    return lines.join('\n');
  }

  static String _preferences(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (!snapshot.preferencesKnown) return l10n.assistantGuidePrefsNone;
    final parts = <String>[
      if (snapshot.dietTypeName != null) _diet(context, snapshot.dietTypeName!),
      ...snapshot.allergies.map((item) => _allergy(context, item)),
      ...snapshot.dislikes,
    ].where((item) => item.trim().isNotEmpty);
    if (parts.isEmpty) return l10n.assistantGuidePrefsNone;
    return l10n.assistantGuidePrefsKnown(parts.join(', '));
  }

  static String _plan(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (snapshot.planLines.isEmpty) return l10n.assistantGuidePlanEmpty;
    final lines = <String>[l10n.assistantGuidePlanHeading];
    for (final raw in snapshot.planLines) {
      final parts = raw.split(AssistantGuideEngine.planSeparator);
      if (parts.length < 4) {
        lines.add('• $raw');
        continue;
      }
      final calories = double.tryParse(parts[3]) ?? 0;
      lines.add(
        '• ${_day(context, parts[0])} ${_meal(context, parts[1])}: ${parts[2]} (${l10n.kcalValue(_kcal(context, calories))})',
      );
    }
    return lines.join('\n');
  }

  static String _shopping(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    if (snapshot.recordsMissing) return l10n.assistantGuideShoppingEmpty;
    final lines = <String>[
      l10n.assistantGuideShopping(snapshot.shoppingManual, snapshot.shoppingFromPlan),
    ];
    if (snapshot.shoppingManualNames.isNotEmpty) {
      lines.add(l10n.assistantGuideShoppingManual(snapshot.shoppingManualNames.join(', ')));
    }
    return lines.join('\n');
  }

  static String _weight(BuildContext context, GuideSnapshot snapshot) {
    final l10n = context.l10n;
    final current = snapshot.weightKg;
    if (current == null) return l10n.assistantWeightEmpty;
    final start = snapshot.startWeightKg ?? current;
    final lines = <String>[
      l10n.assistantWeightProgress(
        ProgressFormat.kg(context, start),
        ProgressFormat.kg(context, current),
        ProgressFormat.signed(context, current - start),
      ),
    ];
    final target = snapshot.targetWeightKg;
    if (target != null) {
      lines.add(
        l10n.assistantWeightTarget(
          ProgressFormat.kg(context, target),
          ProgressFormat.kg(context, (current - target).abs()),
        ),
      );
    }
    lines.add(l10n.assistantWeightNote);
    return lines.join('\n');
  }

  static String _kcal(BuildContext context, double value) => AppFormat.integer(context, value);

  static String _day(BuildContext context, String dayKey) {
    final date = AssistantCalendar.tryParseDayKey(dayKey);
    if (date == null) return dayKey;
    return AppFormat.date(context, date);
  }

  static String _meal(BuildContext context, String name) {
    for (final type in MealType.values) {
      if (type.name == name) return type.label(context.l10n);
    }
    return name;
  }

  static String _meals(BuildContext context, List<String> names) {
    if (names.isEmpty) return context.l10n.assistantGuideNone;
    return names.map((name) => _meal(context, name)).join(', ');
  }

  static String _tags(BuildContext context, List<String> names) {
    final l10n = context.l10n;
    return names
        .map(
          (name) => switch (name) {
            'vegetable' => l10n.assistantFoodTagVegetable,
            'fruit' => l10n.assistantFoodTagFruit,
            'wholeGrain' => l10n.assistantFoodTagWholeGrain,
            'processed' => l10n.assistantFoodTagProcessed,
            _ => name,
          },
        )
        .join(', ');
  }

  static String _diet(BuildContext context, String name) {
    for (final type in DietType.values) {
      if (type.name == name) return type.label(context.l10n);
    }
    return name;
  }

  static String _allergy(BuildContext context, String raw) {
    final parsed = Allergen.tryParse(raw.trim());
    if (parsed == null) return raw;
    return parsed.label(context.l10n);
  }
}

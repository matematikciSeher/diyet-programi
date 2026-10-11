import 'package:flutter/widgets.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../../fasting/domain/models/fasting_schedule.dart';
import '../../fasting/presentation/pages/fasting_page.dart';
import '../../progress/presentation/progress_labels.dart';
import '../domain/models/assistant_grounded_facts.dart';
import '../domain/models/assistant_reply.dart';
import 'assistant_guide_text.dart';

/// Yapılandırılmış yanıtı kullanıcının dilinde metne çevirir.
abstract final class AssistantReplyText {
  static String of(BuildContext context, AssistantReply reply) {
    final l10n = context.l10n;
    String kcal(double v) => AppFormat.integer(context, v);
    String g(double v) => AppFormat.integer(context, v);

    return switch (reply) {
      RemainingCaloriesReply(:final consumed, :final target, :final remaining) =>
        remaining >= 0
            ? l10n.assistantRemainingCalories(
                kcal(consumed),
                kcal(target),
                kcal(remaining),
              )
            : l10n.assistantOverCaloriesInfo(
                kcal(consumed),
                kcal(target),
                kcal(-remaining),
              ),
      ProteinStatusReply(:final consumed, :final target, :final remaining) =>
        consumed >= target
            ? l10n.assistantProteinReached(g(consumed), g(target))
            : l10n.assistantProteinRemaining(g(consumed), g(target), g(remaining)),
      MealSuggestionReply(
        :final mealType,
        :final remainingCalories,
        :final fromPlan,
        :final suggestions,
      ) =>
        [
          if (remainingCalories <= 0)
            l10n.assistantSuggestionOver(mealType.label(l10n))
          else if (remainingCalories < 300)
            l10n.assistantSuggestionLight(
              mealType.label(l10n),
              kcal(remainingCalories),
            )
          else
            l10n.assistantSuggestionIntro(
              mealType.label(l10n),
              kcal(remainingCalories),
            ),
          if (fromPlan != null)
            '• ${l10n.assistantSuggestionFromPlan(fromPlan.title, kcal(fromPlan.nutrition.calories))}',
          for (final s in suggestions)
            '• ${s.title} (${l10n.kcalValue(kcal(s.nutrition.calories))}, '
                '${l10n.gramsValue(g(s.nutrition.proteinG))} ${l10n.macroProtein.toLowerCase()})',
          if (fromPlan == null && suggestions.isEmpty)
            l10n.assistantSuggestionNone,
        ].join('\n'),
      SwapPlanReply(:final meal) =>
        meal == null
            ? l10n.assistantSwapGeneral
            : l10n.assistantSwapMeal(meal.mealType.label(l10n), meal.title),
      OverTargetReply(:final overCalories) =>
        overCalories > 0
            ? l10n.assistantOverTarget(kcal(overCalories))
            : l10n.assistantOverTargetNotReally,
      WaterStatusReply(:final consumedMl, :final goalMl) =>
        consumedMl >= goalMl
            ? l10n.assistantWaterReached(
                AppFormat.liters(context, consumedMl),
              )
            : l10n.assistantWaterRemaining(
                AppFormat.liters(context, consumedMl),
                AppFormat.liters(context, goalMl),
                AppFormat.liters(context, goalMl - consumedMl),
              ),
      WeightProgressReply(
        :final startKg,
        :final currentKg,
        :final targetKg,
        :final latestWaistCm,
      ) =>
        currentKg == null
            ? l10n.assistantWeightEmpty
            : [
                l10n.assistantWeightProgress(
                  ProgressFormat.kg(context, startKg ?? currentKg),
                  ProgressFormat.kg(context, currentKg),
                  ProgressFormat.signed(context, currentKg - (startKg ?? currentKg)),
                ),
                if (targetKg != null)
                  l10n.assistantWeightTarget(
                    ProgressFormat.kg(context, targetKg),
                    ProgressFormat.kg(context, (currentKg - targetKg).abs()),
                  ),
                if (latestWaistCm != null)
                  l10n.assistantWaist(
                    l10n.progressCm(AppFormat.decimal(context, latestWaistCm)),
                  ),
                l10n.assistantWeightNote,
              ].join('\n'),
      FastingStatusReply(:final phase, :final remaining) => switch (phase) {
        null => l10n.assistantFastingNone,
        FastingPhase.fasting => l10n.assistantFastingActive(
          formatClock(remaining ?? Duration.zero),
        ),
        FastingPhase.eating => l10n.assistantFastingEating(
          formatClock(remaining ?? Duration.zero),
        ),
      },
      MacroStatusReply(:final macro, :final consumed, :final target, :final remaining) =>
        consumed >= target
            ? l10n.assistantMacroReached(
                _macroName(l10n, macro),
                g(consumed),
                g(target),
              )
            : l10n.assistantMacroRemaining(
                _macroName(l10n, macro),
                g(consumed),
                g(target),
                g(remaining),
              ),
      DailyNutritionReply(
        :final mealCount,
        :final consumedCalories,
        :final targetCalories,
        :final proteinConsumed,
        :final proteinTarget,
        :final carbsConsumed,
        :final carbsTarget,
        :final fatConsumed,
        :final fatTarget,
        :final macrosRecorded,
        :final hint,
        :final targetBelowSafeFloor,
      ) =>
        [
          l10n.assistantDailyIntro(
            mealCount,
            kcal(consumedCalories),
            kcal(targetCalories),
          ),
          if (!macrosRecorded)
            l10n.assistantMissingMacros
          else ...[
            l10n.assistantMacroLine(
              l10n.macroProtein,
              g(proteinConsumed),
              g(proteinTarget),
            ),
            l10n.assistantMacroLine(
              l10n.macroCarbs,
              g(carbsConsumed),
              g(carbsTarget),
            ),
            l10n.assistantMacroLine(
              l10n.macroFat,
              g(fatConsumed),
              g(fatTarget),
            ),
          ],
          switch (hint) {
            DailyNutritionHint.overCalories => l10n.assistantDailyOver(
              kcal(consumedCalories - targetCalories),
            ),
            DailyNutritionHint.proteinShort => l10n.assistantDailyProteinShort(
              g(proteinConsumed),
              g(proteinTarget),
            ),
            DailyNutritionHint.onTrack => l10n.assistantDailyOnTrack,
          },
          if (targetBelowSafeFloor) l10n.assistantDailyTargetLow,
        ].join('\n'),
      MissingRecordReply(:final record) => switch (record) {
        MissingRecord.meals => l10n.assistantMissingMeals,
        MissingRecord.macros => l10n.assistantMissingMacros,
        MissingRecord.plan => l10n.assistantMissingPlan,
      },
      PlanStatusReply(:final meals) => [
        l10n.assistantPlanHeading,
        for (final meal in meals)
          meal.nutrition.calories > 0
              ? '• ${meal.mealType.label(l10n)}: ${meal.title} (${l10n.kcalValue(kcal(meal.nutrition.calories))})'
              : '• ${meal.mealType.label(l10n)}: ${meal.title} (${l10n.assistantNutritionUnrecorded})',
      ].join('\n'),
      SafetyReply(:final concern) => switch (concern) {
        SafetyConcern.medical => l10n.assistantSafetyMedical,
        SafetyConcern.eatingDisorder => l10n.assistantSafetyEatingDisorder,
        SafetyConcern.extremeRestriction =>
          l10n.assistantSafetyRestriction,
        SafetyConcern.emergency => l10n.assistantSafetyEmergency,
      },
      HelpReply() => l10n.assistantHelp,
      UnavailableAssistantReply(:final code) =>
        code == AssistantErrorCodes.premiumRequired
            ? l10n.assistantPremiumRequired
            : l10n.assistantNotConfigured,
      final GuideReply guide => AssistantGuideText.of(context, guide),
      AssistantFailureReply(:final code) => failureText(l10n, code),
      InterpretedReply(
        :final facts,
        :final recipes,
        :final commentary,
        :final commentarySuppressed,
      ) =>
        _interpreted(
          context,
          facts: facts,
          recipes: recipes,
          commentary: commentary,
          commentarySuppressed: commentarySuppressed,
        ),
    };
  }

  static String failureText(AppLocalizations l10n, String code) =>
      switch (code) {
        AssistantErrorCodes.notConfigured => l10n.assistantNotConfigured,
        AssistantErrorCodes.offline => l10n.assistantOffline,
        AssistantErrorCodes.timeout => l10n.assistantTimeout,
        AssistantErrorCodes.rateLimited => l10n.assistantRateLimited,
        AssistantErrorCodes.invalidResponse => l10n.assistantInvalidResponse,
        AssistantErrorCodes.emptyResponse => l10n.assistantEmptyResponse,
        AssistantErrorCodes.malformed => l10n.assistantMalformed,
        AssistantErrorCodes.messageTooLong => l10n.assistantMessageTooLong,
        AssistantErrorCodes.premiumRequired => l10n.assistantPremiumRequired,
        _ => l10n.assistantUnavailable,
      };

  static String _interpreted(
    BuildContext context, {
    required AssistantGroundedFacts facts,
    required List<AssistantRecipeRef> recipes,
    required String? commentary,
    required bool commentarySuppressed,
  }) {
    final l10n = context.l10n;
    String kcal(double value) => AppFormat.integer(context, value);
    final lines = <String>[];
    if (facts.hasVisibleRecord) {
      lines.add(l10n.assistantRecordsLabel);
      if (facts.showCalories && facts.consumedCalories != null) {
        if (facts.targetsKnown && facts.calorieTarget != null) {
          final remaining = facts.calorieTarget! - facts.consumedCalories!;
          lines.add(
            remaining >= 0
                ? l10n.assistantRemainingCalories(
                    kcal(facts.consumedCalories!),
                    kcal(facts.calorieTarget!),
                    kcal(remaining),
                  )
                : l10n.assistantOverCaloriesInfo(
                    kcal(facts.consumedCalories!),
                    kcal(facts.calorieTarget!),
                    kcal(-remaining),
                  ),
          );
        } else {
          lines.add(
            l10n.assistantConsumedOnly(kcal(facts.consumedCalories!)),
          );
          if (facts.missing.contains('targets')) {
            lines.add(l10n.assistantMissingInfo);
          }
        }
      }
      if (facts.showProtein && facts.consumedProteinG != null) {
        if (facts.proteinTargetG != null) {
          final remaining = facts.proteinTargetG! - facts.consumedProteinG!;
          lines.add(
            facts.consumedProteinG! >= facts.proteinTargetG!
                ? l10n.assistantProteinReached(
                    kcal(facts.consumedProteinG!),
                    kcal(facts.proteinTargetG!),
                  )
                : l10n.assistantProteinRemaining(
                    kcal(facts.consumedProteinG!),
                    kcal(facts.proteinTargetG!),
                    kcal(remaining),
                  ),
          );
        }
      }
      if (facts.showCarbs && facts.consumedCarbsG != null && facts.carbTargetG != null) {
        lines.add(
          l10n.assistantMacroLine(
            l10n.macroCarbs,
            kcal(facts.consumedCarbsG!),
            kcal(facts.carbTargetG!),
          ),
        );
      }
      if (facts.showFat && facts.consumedFatG != null && facts.fatTargetG != null) {
        lines.add(
          l10n.assistantMacroLine(
            l10n.macroFat,
            kcal(facts.consumedFatG!),
            kcal(facts.fatTargetG!),
          ),
        );
      }
      if (facts.showWater && facts.waterMl != null) {
        final goal = facts.waterGoalMl;
        lines.add(
          goal == null
              ? l10n.assistantWaterOnly(AppFormat.liters(context, facts.waterMl!))
              : facts.waterMl! >= goal
              ? l10n.assistantWaterReached(AppFormat.liters(context, facts.waterMl!))
              : l10n.assistantWaterRemaining(
                  AppFormat.liters(context, facts.waterMl!),
                  AppFormat.liters(context, goal),
                  AppFormat.liters(context, goal - facts.waterMl!),
                ),
        );
      }
      if (facts.showActivity) {
        if (!facts.stepsKnown && facts.missing.contains('steps')) {
          lines.add(l10n.assistantMissingInfo);
        }
        if (facts.stepsKnown && facts.steps != null) {
          lines.add(l10n.assistantActivitySteps(facts.steps!));
        }
        if (facts.distanceKnown && facts.distanceMeters != null) {
          lines.add(
            l10n.assistantActivityDistance(
              AppFormat.decimal(context, facts.distanceMeters! / 1000),
            ),
          );
        }
        if (facts.activeCaloriesKnown && facts.activeCalories != null) {
          lines.add(l10n.assistantActivityCalories(kcal(facts.activeCalories!)));
        }
        if (facts.workoutsKnown && facts.workoutCount != null) {
          lines.add(l10n.assistantActivityWorkouts(facts.workoutCount!));
        }
      }
      if (facts.showPlan) {
        if (facts.planLines.isEmpty) {
          lines.add(l10n.assistantPlanEmpty);
        } else {
          lines.addAll(facts.planLines.map((line) => '• $line'));
        }
      }
    }
    if (recipes.isNotEmpty) {
      lines.add(l10n.assistantRecipeHeading);
      for (final recipe in recipes) {
        lines.add(
          '• ${l10n.assistantRecipeLine(recipe.title, kcal(recipe.calories), kcal(recipe.proteinG))}',
        );
      }
    }
    if (commentarySuppressed) {
      lines.add(l10n.assistantAllergyBlocked);
    } else if (commentary != null && commentary.isNotEmpty) {
      if (lines.isNotEmpty) lines.add(l10n.assistantCommentaryLabel);
      lines.add(commentary);
    }
    if (lines.isEmpty) return l10n.assistantMissingInfo;
    return lines.join('\n');
  }

  static String _macroName(AppLocalizations l10n, TrackedMacro macro) =>
      switch (macro) {
        TrackedMacro.carbs => l10n.macroCarbs,
        TrackedMacro.fat => l10n.macroFat,
      };
}

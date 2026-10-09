import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../domain/models/plan_ingredient.dart';
import '../domain/models/planned_meal.dart';
import '../domain/usecases/apply_plan_change.dart';

extension PlanIngredientL10n on PlanIngredient {
  String label(AppLocalizations l10n) => switch (this) {
    PlanIngredient.chicken => l10n.planIngredientChicken,
    PlanIngredient.redMeat => l10n.planIngredientRedMeat,
    PlanIngredient.fish => l10n.planIngredientFish,
    PlanIngredient.shellfish => l10n.planIngredientShellfish,
    PlanIngredient.egg => l10n.planIngredientEgg,
    PlanIngredient.milk => l10n.planIngredientMilk,
    PlanIngredient.cheese => l10n.planIngredientCheese,
    PlanIngredient.yogurt => l10n.planIngredientYogurt,
    PlanIngredient.legumes => l10n.planIngredientLegumes,
    PlanIngredient.gluten => l10n.planIngredientGluten,
    PlanIngredient.oats => l10n.planIngredientOats,
    PlanIngredient.nuts => l10n.planIngredientNuts,
    PlanIngredient.peanut => l10n.planIngredientPeanut,
    PlanIngredient.sesame => l10n.planIngredientSesame,
    PlanIngredient.soy => l10n.planIngredientSoy,
    PlanIngredient.eggplant => l10n.planIngredientEggplant,
    PlanIngredient.mushroom => l10n.planIngredientMushroom,
  };
}

/// Plan asistanının [outcome] için yanıt metni.
abstract final class PlanChangeMessages {
  static String describe(AppLocalizations l10n, PlanChangeOutcome outcome) {
    final request = outcome.request;
    String ingredients(Set<PlanIngredient> values) =>
        values.toList().map((i) => i.label(l10n)).join(', ');
    String mealName(PlannedMeal m) => m.mealType.label(l10n);
    final changeLines = [
      for (final c in outcome.changes)
        l10n.planReplyChangeLine(
          mealName(c.before),
          c.before.title,
          c.after.title,
        ),
    ];
    final missing = [
      for (final m in outcome.noAlternative)
        l10n.planReplyNoAlternative(mealName(m)),
    ];

    final lines = <String>[];
    switch (outcome.kind) {
      case PlanChangeKind.notUnderstood:
        lines.add(l10n.planReplyNotUnderstood);
      case PlanChangeKind.regenerated:
        lines.add(l10n.planReplyRegenerated);
      case PlanChangeKind.swapped:
        if (changeLines.isNotEmpty) lines.add(l10n.planReplySwapped);
        lines
          ..addAll(changeLines)
          ..addAll(missing);
      case PlanChangeKind.dietChanged:
        final diet = request.diet!.label(l10n);
        lines
          ..add(
            outcome.changed
                ? l10n.planReplyDiet(diet)
                : l10n.planReplyDietUnchanged(diet),
          )
          ..addAll(changeLines)
          ..addAll(missing);
      case PlanChangeKind.excluded:
        final names = ingredients(request.excluded);
        if (outcome.changed) {
          lines
            ..add(l10n.planReplyExcluded(names))
            ..addAll(changeLines);
        } else if (outcome.noAlternative.isEmpty) {
          lines.add(l10n.planReplyAlreadyAbsent(names));
        }
        lines.addAll(missing);
        if (outcome.remember) lines.add(l10n.planReplyRemembered(names));
      case PlanChangeKind.preferred:
        final names = ingredients(request.preferred);
        if (outcome.changed) {
          lines
            ..add(l10n.planReplyPreferred(names))
            ..addAll(changeLines);
        } else if (outcome.alreadyMatching.isNotEmpty) {
          lines.add(
            l10n.planReplyAlreadyPresent(
              names,
              outcome.alreadyMatching.map(mealName).toSet().join(', '),
            ),
          );
        } else {
          lines.add(l10n.planReplyPreferredNone(names));
        }
    }
    return lines.join('\n');
  }
}

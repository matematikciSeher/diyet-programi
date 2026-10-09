import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/services/nutrition/nutrition_calculator.dart';
import '../../domain/models/onboarding_draft.dart';
import '../../domain/models/onboarding_step.dart';
import '../providers/onboarding_flow_controller.dart';
import 'measurement_input.dart';
import 'onboarding_messages.dart';
import 'option_tile.dart';
import 'step_layout.dart';
import 'tag_selector.dart';

/// Soru adımının içeriği.
class QuestionStep extends StatelessWidget {
  const QuestionStep({super.key, required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      OnboardingStep.name => const _NameStep(),
      OnboardingStep.goal => const _GoalStep(),
      OnboardingStep.gender => const _GenderStep(),
      OnboardingStep.age => const _AgeStep(),
      OnboardingStep.height => const _HeightStep(),
      OnboardingStep.weight => const _WeightStep(),
      OnboardingStep.targetWeight => const _TargetWeightStep(),
      OnboardingStep.activityLevel => const _ActivityStep(),
      OnboardingStep.exerciseFrequency => const _ExerciseStep(),
      OnboardingStep.dietType => const _DietStep(),
      OnboardingStep.allergies => const _AllergiesStep(),
      OnboardingStep.dislikedFoods => const _DislikedFoodsStep(),
      OnboardingStep.mealsPerDay => const _MealsStep(),
      OnboardingStep.breakfast => const _BreakfastStep(),
      OnboardingStep.water => const _WaterStep(),
      OnboardingStep.fasting => const _FastingStep(),
      OnboardingStep.targetDate => const _TargetDateStep(),
      _ => const SizedBox.shrink(),
    };
  }
}

// --- Ortak yardımcılar ---

extension on WidgetRef {
  OnboardingDraft get draft => watch(onboardingFlowProvider).draft;

  void updateDraft(OnboardingDraft Function(OnboardingDraft d) change) =>
      read(onboardingFlowProvider.notifier).update(change);

  void goNext() => read(onboardingFlowProvider.notifier).next();
}

String? _visibleError(BuildContext context, WidgetRef ref) =>
    ref.watch(onboardingFlowProvider).visibleError?.message(context);

class _ErrorLine extends ConsumerWidget {
  const _ErrorLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = _visibleError(context, ref);
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: InlineMessage(message: message),
    );
  }
}

class _SelectionStep<T> extends ConsumerWidget {
  const _SelectionStep({
    required this.title,
    required this.values,
    required this.selectedOf,
    required this.apply,
    required this.titleOf,
    this.subtitle,
    this.subtitleOf,
    this.iconOf,
    this.leadingOf,
    this.footer,
  });

  final String title;
  final String? subtitle;
  final List<T> values;
  final T? Function(OnboardingDraft draft) selectedOf;
  final OnboardingDraft Function(OnboardingDraft draft, T value) apply;
  final String Function(T value) titleOf;
  final String? Function(T value)? subtitleOf;
  final IconData? Function(T value)? iconOf;
  final Widget? Function(T value, {required bool selected})? leadingOf;
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StepLayout(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionList<T>(
            values: values,
            selected: selectedOf(ref.draft),
            onSelected: (v) => ref.updateDraft((d) => apply(d, v)),
            titleOf: titleOf,
            subtitleOf: subtitleOf,
            iconOf: iconOf,
            leadingOf: leadingOf,
          ),
          const _ErrorLine(),
          if (footer != null) ...[AppSpacing.gapXl, footer!],
        ],
      ),
    );
  }
}

class _MeasurementStep extends ConsumerWidget {
  const _MeasurementStep({
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.min,
    required this.max,
    required this.valueOf,
    required this.apply,
    this.allowDecimal = false,
    this.extra,
  });

  final String title;
  final String subtitle;
  final String unit;
  final num min;
  final num max;
  final bool allowDecimal;
  final num? Function(OnboardingDraft draft) valueOf;
  final OnboardingDraft Function(OnboardingDraft draft, num? value) apply;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = valueOf(ref.read(onboardingFlowProvider).draft);
    return StepLayout(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MeasurementInput(
            initialValue: initial,
            unit: unit,
            allowDecimal: allowDecimal,
            onChanged: (v) => ref.updateDraft((d) => apply(d, v)),
            onSubmitted: ref.goNext,
            errorText: _visibleError(context, ref),
            helperText: context.l10n.inputRangeHint(
              AppFormat.decimal(context, min),
              AppFormat.decimal(context, max),
              unit,
            ),
          ),
          if (extra != null) ...[AppSpacing.gapXl, extra!],
        ],
      ),
    );
  }
}

// --- Adımlar ---

class _NameStep extends ConsumerStatefulWidget {
  const _NameStep();

  @override
  ConsumerState<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<_NameStep> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(onboardingFlowProvider).draft.name ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StepLayout(
      title: l10n.qNameTitle,
      subtitle: l10n.qNameSubtitle,
      optional: true,
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.givenName],
        style: context.textStyles.titleLarge,
        onChanged: (v) => ref.updateDraft((d) => d.copyWith(name: v)),
        onSubmitted: (_) => ref.goNext(),
        decoration: InputDecoration(
          hintText: l10n.qNameHint,
          counterText: '',
          prefixIcon: const Icon(Icons.person_outline_rounded),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<GoalType>(
      title: l10n.qGoalTitle,
      subtitle: l10n.qGoalSubtitle,
      values: GoalType.values,
      selectedOf: (d) => d.goal,
      apply: (d, v) => d.copyWith(goal: v),
      titleOf: (v) => v.label(l10n),
      subtitleOf: (v) => v.description(l10n),
      iconOf: (v) => v.icon,
    );
  }
}

class _GenderStep extends StatelessWidget {
  const _GenderStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<Gender>(
      title: l10n.qGenderTitle,
      subtitle: l10n.qGenderSubtitle,
      values: Gender.values,
      selectedOf: (d) => d.gender,
      apply: (d, v) => d.copyWith(gender: v),
      titleOf: (v) => v.label(l10n),
      subtitleOf: (v) =>
          v == Gender.unspecified ? l10n.genderUnspecifiedDesc : null,
      iconOf: (v) => v.icon,
    );
  }
}

class _AgeStep extends StatelessWidget {
  const _AgeStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MeasurementStep(
      title: l10n.qAgeTitle,
      subtitle: l10n.qAgeSubtitle,
      unit: l10n.unitYears,
      min: AppConstants.minAge,
      max: AppConstants.maxAge,
      valueOf: (d) => d.age,
      apply: (d, v) => d.copyWith(age: v?.round()),
    );
  }
}

class _HeightStep extends StatelessWidget {
  const _HeightStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MeasurementStep(
      title: l10n.qHeightTitle,
      subtitle: l10n.qHeightSubtitle,
      unit: l10n.unitCm,
      min: AppConstants.minHeightCm,
      max: AppConstants.maxHeightCm,
      allowDecimal: true,
      valueOf: (d) => d.height,
      apply: (d, v) => d.copyWith(height: v?.toDouble()),
    );
  }
}

class _WeightStep extends StatelessWidget {
  const _WeightStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MeasurementStep(
      title: l10n.qWeightTitle,
      subtitle: l10n.qWeightSubtitle,
      unit: l10n.unitKg,
      min: AppConstants.minWeightKg,
      max: AppConstants.maxWeightKg,
      allowDecimal: true,
      valueOf: (d) => d.weight,
      apply: (d, v) => d.copyWith(weight: v?.toDouble()),
    );
  }
}

class _TargetWeightStep extends StatelessWidget {
  const _TargetWeightStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _MeasurementStep(
      title: l10n.qTargetWeightTitle,
      subtitle: l10n.qTargetWeightSubtitle,
      unit: l10n.unitKg,
      min: AppConstants.minWeightKg,
      max: AppConstants.maxWeightKg,
      allowDecimal: true,
      valueOf: (d) => d.targetWeight,
      apply: (d, v) => d.copyWith(targetWeight: v?.toDouble()),
      extra: const _TargetWeightInfo(),
    );
  }
}

class _TargetWeightInfo extends ConsumerWidget {
  const _TargetWeightInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.draft;
    final current = draft.weight;
    final target = draft.targetWeight;
    final height = draft.height;
    if (current == null) return const SizedBox.shrink();

    final diff = target == null ? null : target - current;
    final lines = <(IconData, String)>[
      (
        Icons.monitor_weight_outlined,
        l10n.targetWeightCurrent(AppFormat.decimal(context, current)),
      ),
      if (diff != null && diff.abs() >= 0.1)
        (
          diff < 0 ? Icons.south_rounded : Icons.north_rounded,
          l10n.targetWeightDiff(
            '${diff > 0 ? '+' : '−'}${AppFormat.decimal(context, diff.abs())}',
          ),
        ),
      if (height != null && draft.goal == GoalType.loseWeight)
        (
          Icons.health_and_safety_outlined,
          l10n.targetWeightHealthyMin(
            AppFormat.decimal(
              context,
              NutritionCalculator.minHealthyWeight(height),
            ),
          ),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, text) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppSizes.iconSm,
                    color: context.colors.primary,
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: Text(text, style: context.textStyles.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<ActivityLevel>(
      title: l10n.qActivityTitle,
      subtitle: l10n.qActivitySubtitle,
      values: ActivityLevel.values,
      selectedOf: (d) => d.activityLevel,
      apply: (d, v) => d.copyWith(activityLevel: v),
      titleOf: (v) => v.label(l10n),
      subtitleOf: (v) => v.description(l10n),
      iconOf: (v) => v.icon,
    );
  }
}

class _ExerciseStep extends StatelessWidget {
  const _ExerciseStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<ExerciseFrequency>(
      title: l10n.qExerciseTitle,
      subtitle: l10n.qExerciseSubtitle,
      values: ExerciseFrequency.values,
      selectedOf: (d) => d.exerciseFrequency,
      apply: (d, v) => d.copyWith(exerciseFrequency: v),
      titleOf: (v) => v.label(l10n),
      iconOf: (v) => v == ExerciseFrequency.none
          ? Icons.hotel_outlined
          : Icons.fitness_center_rounded,
    );
  }
}

class _DietStep extends StatelessWidget {
  const _DietStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<DietType>(
      title: l10n.qDietTitle,
      subtitle: l10n.qDietSubtitle,
      values: DietType.values,
      selectedOf: (d) => d.dietType,
      apply: (d, v) => d.copyWith(dietType: v),
      titleOf: (v) => v.label(l10n),
      subtitleOf: (v) => v.description(l10n),
      iconOf: (v) => v.icon,
    );
  }
}

class _AllergiesStep extends ConsumerWidget {
  const _AllergiesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return StepLayout(
      title: l10n.qAllergiesTitle,
      subtitle: l10n.qAllergiesSubtitle,
      child: TagSelector(
        noneLabel: l10n.allergyNone,
        customHint: l10n.allergyOtherHint,
        options: [
          for (final a in Allergen.values)
            (value: a.name, label: a.label(l10n)),
        ],
        selected: ref.draft.allergies,
        onChanged: (v) => ref.updateDraft((d) => d.copyWith(allergies: v)),
      ),
    );
  }
}

class _DislikedFoodsStep extends ConsumerWidget {
  const _DislikedFoodsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final suggestions = [
      l10n.foodOnion,
      l10n.foodGarlic,
      l10n.foodMushroom,
      l10n.foodEggplant,
      l10n.foodOffal,
      l10n.foodSeafood,
      l10n.foodOlive,
      l10n.foodSpicy,
      l10n.foodBroccoli,
      l10n.foodLegumes,
      l10n.foodCoriander,
      l10n.foodCelery,
    ];
    return StepLayout(
      title: l10n.qDislikedTitle,
      subtitle: l10n.qDislikedSubtitle,
      optional: true,
      child: TagSelector(
        customHint: l10n.dislikedHint,
        options: [for (final s in suggestions) (value: s, label: s)],
        selected: ref.draft.dislikedFoods,
        onChanged: (v) => ref.updateDraft((d) => d.copyWith(dislikedFoods: v)),
      ),
    );
  }
}

class _MealsStep extends StatelessWidget {
  const _MealsStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<int>(
      title: l10n.qMealsTitle,
      subtitle: l10n.qMealsSubtitle,
      values: const [2, 3, 4, 5],
      selectedOf: (d) => d.mealsPerDay,
      apply: (d, v) => d.copyWith(mealsPerDay: v),
      titleOf: l10n.mealsCount,
      subtitleOf: (v) => switch (v) {
        2 => l10n.meals2Desc,
        3 => l10n.meals3Desc,
        4 => l10n.meals4Desc,
        _ => l10n.meals5Desc,
      },
      leadingOf: (v, {required selected}) => Text(
        '$v',
        style: context.textStyles.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? context.colors.primary : null,
        ),
      ),
    );
  }
}

class _BreakfastStep extends StatelessWidget {
  const _BreakfastStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<BreakfastPreference>(
      title: l10n.qBreakfastTitle,
      subtitle: l10n.qBreakfastSubtitle,
      values: BreakfastPreference.values,
      selectedOf: (d) => d.breakfastPreference,
      apply: (d, v) => d.copyWith(breakfastPreference: v),
      titleOf: (v) => v.label(l10n),
      iconOf: (v) => v.icon,
    );
  }
}

class _WaterStep extends ConsumerWidget {
  const _WaterStep();

  static const _step = 250;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.draft;
    final recommended = NutritionCalculator.recommendedWaterMl(
      weightKg: draft.weight ?? 70,
      activityLevel: draft.activityLevel ?? ActivityLevel.light,
      exerciseFrequency: draft.exerciseFrequency ?? ExerciseFrequency.none,
    );
    final value = (draft.waterGoal ?? recommended).clamp(
      AppConstants.minWaterGoalMl,
      AppConstants.maxWaterGoalMl,
    );
    final waterColor = context.nutritionColors.water;

    return StepLayout(
      title: l10n.qWaterTitle,
      subtitle: l10n.qWaterSubtitle,
      child: Column(
        children: [
          Icon(Icons.water_drop_rounded, size: 56, color: waterColor),
          AppSpacing.gapMd,
          Text(
            l10n.waterLiters(AppFormat.liters(context, value)),
            style: context.textStyles.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.waterGlasses((value / _step).round()),
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapXl,
          Slider(
            value: value.toDouble(),
            min: AppConstants.minWaterGoalMl.toDouble(),
            max: AppConstants.maxWaterGoalMl.toDouble(),
            divisions:
                (AppConstants.maxWaterGoalMl - AppConstants.minWaterGoalMl) ~/
                _step,
            activeColor: waterColor,
            label: l10n.waterLiters(AppFormat.liters(context, value)),
            onChanged: (v) =>
                ref.updateDraft((d) => d.copyWith(waterGoal: v.round())),
          ),
          AppSpacing.gapSm,
          Text(
            l10n.waterRecommended(AppFormat.liters(context, recommended)),
            style: context.textStyles.bodyMedium,
          ),
          if (value != recommended)
            TextButton.icon(
              onPressed: () =>
                  ref.updateDraft((d) => d.copyWith(waterGoal: recommended)),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(l10n.waterUseRecommended),
            ),
          const _ErrorLine(),
        ],
      ),
    );
  }
}

class _FastingStep extends StatelessWidget {
  const _FastingStep();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _SelectionStep<FastingPreference>(
      title: l10n.qFastingTitle,
      subtitle: l10n.qFastingSubtitle,
      values: FastingPreference.onboardingOptions,
      selectedOf: (d) => d.fastingPreference,
      apply: (d, v) => d.copyWith(fastingPreference: v),
      titleOf: (v) => v.label(l10n),
      subtitleOf: (v) => v.description(l10n),
      iconOf: (v) => v == FastingPreference.none
          ? Icons.restaurant_menu_rounded
          : Icons.timer_outlined,
      footer: InlineMessage(
        message: l10n.fastingCautionNote,
        isError: false,
        icon: Icons.medical_information_outlined,
      ),
    );
  }
}

class _TargetDateStep extends ConsumerWidget {
  const _TargetDateStep();

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? suggested,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.add(const Duration(days: 1));
    final last = DateTime(today.year + 5, today.month, today.day);
    var initial =
        ref.read(onboardingFlowProvider).draft.targetDate ??
        suggested ??
        today.add(const Duration(days: 84));
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      ref.updateDraft((d) => d.copyWith(targetDate: picked));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final draft = ref.draft;
    final goal = draft.goal ?? GoalType.loseWeight;
    final suggested = draft.weight == null
        ? null
        : NutritionCalculator.suggestedTargetDate(
            goal: goal,
            weightKg: draft.weight!,
            targetWeightKg: draft.targetWeight,
          );
    final chosen = draft.targetDate;
    final warning = _paceWarning(context, draft);

    return StepLayout(
      title: l10n.qTargetDateTitle,
      subtitle: l10n.qTargetDateSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OptionTile(
            title: l10n.targetDateRecommended,
            subtitle: suggested == null
                ? null
                : l10n.targetDateRecommendedDesc(
                    AppFormat.date(context, suggested),
                  ),
            icon: Icons.verified_outlined,
            selected: chosen == null,
            onTap: () => ref.updateDraft((d) => d.copyWith(targetDate: null)),
          ),
          AppSpacing.gapMd,
          OptionTile(
            title: l10n.targetDateCustom,
            subtitle: chosen == null
                ? l10n.targetDateCustomPick
                : AppFormat.date(context, chosen),
            icon: Icons.event_outlined,
            selected: chosen != null,
            onTap: () => _pickDate(context, ref, suggested),
          ),
          if (warning != null) ...[
            AppSpacing.gapLg,
            InlineMessage(message: warning, isError: false),
          ],
          const _ErrorLine(),
        ],
      ),
    );
  }

  String? _paceWarning(BuildContext context, OnboardingDraft draft) {
    final date = draft.targetDate;
    final weight = draft.weight;
    final target = draft.targetWeight;
    final goal = draft.goal;
    if (date == null || weight == null || target == null || goal == null) {
      return null;
    }
    final now = DateTime.now();
    final days = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days <= 0) return null;
    final required = (target - weight).abs() / (days / 7);
    final max = switch (goal) {
      GoalType.loseWeight => NutritionCalculator.maxSafeWeeklyLoss(weight),
      GoalType.buildMuscle => NutritionCalculator.maxMuscleGainPerWeek,
      _ => NutritionCalculator.maxGainPerWeek,
    };
    if (required <= max) return null;
    return context.l10n.targetDateTooSoon(
      AppFormat.decimal(context, required, digits: 2),
      AppFormat.decimal(context, max, digits: 2),
    );
  }
}

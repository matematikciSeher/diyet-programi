import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../../shared/services/nutrition/profile_targets_service.dart';
import '../../../onboarding/presentation/widgets/tag_selector.dart';
import '../providers/personal_info_providers.dart';

/// Kullanıcının ortak profili: hedef, diyet, alerji ve öğün tercihleri.
/// Kalori hedefleri burada okunur; kilo Kilo Takibi üzerinden güncellenir.
class PersonalInfoPage extends ConsumerWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featurePersonalInfo)),
      body: AsyncValueView(
        value: profile,
        onRetry: () => ref.invalidate(userProfileProvider),
        data: (value) {
          if (value == null) {
            return EmptyStateView(
              icon: Icons.person_outline_rounded,
              title: l10n.personalInfoEmptyTitle,
              message: l10n.personalInfoEmptyMessage,
            );
          }
          return _PersonalInfoForm(profile: value);
        },
      ),
    );
  }
}

class _PersonalInfoForm extends ConsumerStatefulWidget {
  const _PersonalInfoForm({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends ConsumerState<_PersonalInfoForm> {
  static const _mealOptions = [2, 3, 4, 5, 6];

  late final _name = TextEditingController(text: widget.profile.name ?? '');
  late final _age = TextEditingController(
    text: widget.profile.age?.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: widget.profile.height?.toString() ?? '',
  );
  late final _targetWeight = TextEditingController(
    text: widget.profile.targetWeight?.toString() ?? '',
  );
  late final _water = TextEditingController(
    text: widget.profile.waterGoal?.toString() ?? '',
  );

  late GoalType? _goal = widget.profile.goal;
  late Gender? _gender = widget.profile.gender;
  late ActivityLevel? _activity = widget.profile.activityLevel;
  late DietType _diet = widget.profile.dietType ?? DietType.omnivore;
  late List<String> _allergies = [...widget.profile.allergies];
  late List<String> _disliked = [...widget.profile.dislikedFoods];
  late int _meals = (widget.profile.mealsPerDay ?? 4).clamp(2, 6);
  late BreakfastPreference? _breakfast = widget.profile.breakfastPreference;
  late FastingPreference _fasting =
      widget.profile.fastingPreference ?? FastingPreference.none;

  TargetSuggestion? _suggestion;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _targetWeight.dispose();
    _water.dispose();
    super.dispose();
  }

  UserProfile _draft() {
    final age = int.tryParse(_age.text.trim());
    final height = double.tryParse(_height.text.replaceAll(',', '.').trim());
    final target = double.tryParse(
      _targetWeight.text.replaceAll(',', '.').trim(),
    );
    final water = int.tryParse(_water.text.trim());
    return widget.profile.copyWith(
      name: _name.text.trim().isEmpty ? widget.profile.name : _name.text.trim(),
      age: age,
      gender: _gender,
      height: height,
      targetWeight: target,
      activityLevel: _activity,
      goal: _goal,
      dietType: _diet,
      allergies: _allergies,
      dislikedFoods: _disliked,
      mealsPerDay: _meals,
      breakfastPreference: _breakfast,
      waterGoal: water,
      fastingPreference: _fasting,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final result = await ref.read(personalInfoActionsProvider).save(_draft());
    if (!mounted) return;
    setState(() => _saving = false);
    switch (result) {
      case Success(:final value):
        setState(() => _suggestion = value.suggestion);
        final extra = [
          if (value.planUpdated) l10n.personalInfoPlanUpdated,
        ].join();
        context.showSnack(
          extra.isEmpty ? l10n.personalInfoSaved : extra,
        );
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  Future<void> _applyTargets() async {
    final suggestion = _suggestion;
    if (suggestion == null || _saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(personalInfoActionsProvider)
        .applyTargets(suggestion);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _suggestion = null;
    });
    switch (result) {
      case Success():
        context.showSnack(context.l10n.personalInfoTargetsUpdated);
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.profile;
    final targets = profile.nutritionTargets;
    final current = profile.weight;

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl,
      ),
      children: [
        ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (targets != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.personalInfoTargetsTitle,
                        style: context.textStyles.titleSmall,
                      ),
                      AppSpacing.gapXs,
                      Text(
                        l10n.personalInfoTargetsHint,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Text(
                        l10n.kcalValue(
                          AppFormat.integer(context, targets.calories),
                        ),
                        style: context.textStyles.headlineSmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Text(
                        l10n.macroSummaryShort(
                          AppFormat.integer(context, targets.proteinG),
                          AppFormat.integer(context, targets.carbsG),
                          AppFormat.integer(context, targets.fatG),
                        ),
                        style: context.textStyles.bodyMedium,
                      ),
                      if (_goal != null) ...[
                        AppSpacing.gapSm,
                        Text(
                          l10n.nutritionPlanGoal(_goal!.label(l10n)),
                          style: context.textStyles.labelLarge,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.gapLg,
              ],
              if (_suggestion != null) ...[
                AppCard(
                  color: context.colors.secondaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.kcalValue(
                          AppFormat.integer(context, _suggestion!.calories),
                        ),
                        style: context.textStyles.titleMedium,
                      ),
                      AppSpacing.gapSm,
                      AppButton(
                        label: l10n.personalInfoRecalculate,
                        icon: Icons.refresh_rounded,
                        onPressed: _applyTargets,
                        isLoading: _saving,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
              ],
              SectionHeader(title: l10n.personalInfoBasics),
              AppTextField(
                controller: _name,
                label: l10n.personalInfoName,
                hint: l10n.qNameHint,
                textInputAction: TextInputAction.next,
              ),
              AppSpacing.gapMd,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final g in Gender.values)
                    ChoiceChip(
                      label: Text(g.label(l10n)),
                      selected: _gender == g,
                      onSelected: (_) => setState(() => _gender = g),
                    ),
                ],
              ),
              AppSpacing.gapMd,
              AppTextField(
                controller: _age,
                label: l10n.personalInfoAge,
                suffixText: l10n.unitYears,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              AppSpacing.gapMd,
              AppTextField(
                controller: _height,
                label: l10n.personalInfoHeight,
                suffixText: l10n.unitCm,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppSpacing.gapMd,
              if (current != null) ...[
                Text(
                  l10n.targetWeightCurrent(
                    AppFormat.decimal(context, current),
                  ),
                  style: context.textStyles.titleSmall,
                ),
                AppSpacing.gapXs,
                Text(
                  l10n.personalInfoCurrentWeightHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.weight),
                    child: Text(l10n.personalInfoOpenWeight),
                  ),
                ),
                AppSpacing.gapSm,
              ],
              AppTextField(
                controller: _targetWeight,
                label: l10n.personalInfoTargetWeight,
                suffixText: l10n.unitKg,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppSpacing.gapMd,
              AppTextField(
                controller: _water,
                label: l10n.personalInfoWaterGoal,
                suffixText: 'ml',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                helper: l10n.inputRangeHint(
                  '${AppConstants.minWaterGoalMl}',
                  '${AppConstants.maxWaterGoalMl}',
                  'ml',
                ),
              ),
              AppSpacing.gapXl,
              SectionHeader(title: l10n.qGoalTitle),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final g in GoalType.values)
                    ChoiceChip(
                      avatar: Icon(g.icon, size: AppSizes.iconSm),
                      label: Text(g.label(l10n)),
                      selected: _goal == g,
                      onSelected: (_) => setState(() => _goal = g),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              SectionHeader(title: l10n.qActivityTitle),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final a in ActivityLevel.values)
                    ChoiceChip(
                      label: Text(a.label(l10n)),
                      selected: _activity == a,
                      onSelected: (_) => setState(() => _activity = a),
                    ),
                ],
              ),
              AppSpacing.gapXl,
              SectionHeader(title: l10n.personalInfoPreferences),
              Text(l10n.qDietTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final d in DietType.values)
                    ChoiceChip(
                      label: Text(d.label(l10n)),
                      selected: _diet == d,
                      onSelected: (_) => setState(() => _diet = d),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              Text(l10n.qMealsTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final count in _mealOptions)
                    ChoiceChip(
                      label: Text('$count'),
                      selected: _meals == count,
                      onSelected: (_) => setState(() => _meals = count),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              Text(l10n.qBreakfastTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final b in BreakfastPreference.values)
                    ChoiceChip(
                      label: Text(b.label(l10n)),
                      selected: _breakfast == b,
                      onSelected: (_) => setState(() => _breakfast = b),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              Text(l10n.qFastingTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final f in FastingPreference.onboardingOptions)
                    ChoiceChip(
                      label: Text(f.label(l10n)),
                      selected: _fasting == f,
                      onSelected: (_) => setState(() => _fasting = f),
                    ),
                ],
              ),
              AppSpacing.gapLg,
              Text(l10n.qAllergiesTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              TagSelector(
                options: [
                  for (final a in Allergen.values)
                    (value: a.name, label: a.label(l10n)),
                ],
                selected: _allergies,
                onChanged: (v) => setState(() => _allergies = v),
                customHint: l10n.allergyOtherHint,
                noneLabel: l10n.allergyNone,
              ),
              AppSpacing.gapLg,
              Text(l10n.qDislikedTitle, style: context.textStyles.labelLarge),
              AppSpacing.gapSm,
              TagSelector(
                options: const [],
                selected: _disliked,
                onChanged: (v) => setState(() => _disliked = v),
                customHint: l10n.dislikedHint,
              ),
              AppSpacing.gapXl,
              AppButton(
                label: l10n.actionSave,
                icon: Icons.check_rounded,
                onPressed: _save,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

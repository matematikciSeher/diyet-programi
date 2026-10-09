import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../providers/nutrition_plan_providers.dart';

/// Profildeki hedef, öğün sayısı, diyet tipi ve sevilmeyen yiyeceklerle
/// açılır; kullanıcının değişiklikleri profile yazılmak üzere döner.
Future<NewPlanInput?> showNewPlanSheet(
  BuildContext context, {
  required UserProfile? profile,
}) => showModalBottomSheet<NewPlanInput>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _NewPlanSheet(profile: profile),
);

class _NewPlanSheet extends StatefulWidget {
  const _NewPlanSheet({required this.profile});

  final UserProfile? profile;

  @override
  State<_NewPlanSheet> createState() => _NewPlanSheetState();
}

class _NewPlanSheetState extends State<_NewPlanSheet> {
  static const mealOptions = [2, 3, 4, 5, 6];

  late int _meals = (widget.profile?.mealsPerDay ?? 4).clamp(2, 6);
  late DietType _diet = widget.profile?.dietType ?? DietType.omnivore;
  late final List<String> _disliked = [...?widget.profile?.dislikedFoods];
  final _dislikedInput = TextEditingController();

  @override
  void dispose() {
    _dislikedInput.dispose();
    super.dispose();
  }

  void _addDisliked() {
    final text = _dislikedInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_disliked.any((d) => d.toLowerCase() == text.toLowerCase())) {
        _disliked.add(text);
      }
      _dislikedInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = widget.profile;
    final variant = context.colors.onSurfaceVariant;
    final goal = profile?.goal;
    final kcal = profile?.dailyCalories;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.nutritionPlanCreate,
              style: context.textStyles.titleLarge,
            ),
            AppSpacing.gapXs,
            Text(
              [
                if (goal != null) l10n.nutritionPlanGoal(goal.label(l10n)),
                if (kcal != null)
                  l10n.kcalValue(AppFormat.integer(context, kcal)),
              ].join(' · '),
              style: context.textStyles.bodyMedium?.copyWith(color: variant),
            ),
            AppSpacing.gapXs,
            Text(
              l10n.nutritionPlanFromProfile,
              style: context.textStyles.bodySmall?.copyWith(color: variant),
            ),
            AppSpacing.gapLg,
            Text(
              l10n.nutritionPlanMealsPerDay,
              style: context.textStyles.labelLarge,
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final count in mealOptions)
                  ChoiceChip(
                    label: Text('$count'),
                    selected: _meals == count,
                    onSelected: (_) => setState(() => _meals = count),
                  ),
              ],
            ),
            AppSpacing.gapLg,
            Text(
              l10n.nutritionPlanDietType,
              style: context.textStyles.labelLarge,
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final diet in DietType.values)
                  ChoiceChip(
                    label: Text(diet.label(l10n)),
                    selected: _diet == diet,
                    onSelected: (_) => setState(() => _diet = diet),
                  ),
              ],
            ),
            AppSpacing.gapLg,
            Text(
              l10n.nutritionPlanDisliked,
              style: context.textStyles.labelLarge,
            ),
            AppSpacing.gapSm,
            if (_disliked.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final food in _disliked)
                    InputChip(
                      label: Text(food),
                      onDeleted: () => setState(() => _disliked.remove(food)),
                    ),
                ],
              ),
              AppSpacing.gapSm,
            ],
            AppTextField(
              controller: _dislikedInput,
              hint: l10n.nutritionPlanDislikedHint,
              prefixIcon: Icons.block_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addDisliked(),
              suffix: IconButton(
                tooltip: l10n.actionAdd,
                icon: const Icon(Icons.add_rounded),
                onPressed: _addDisliked,
              ),
            ),
            AppSpacing.gapXl,
            FilledButton.icon(
              onPressed: () {
                final pending = _dislikedInput.text.trim();
                Navigator.of(context).pop((
                  mealsPerDay: _meals,
                  dietType: _diet,
                  dislikedFoods: [
                    ..._disliked,
                    if (pending.isNotEmpty &&
                        !_disliked.any(
                          (d) => d.toLowerCase() == pending.toLowerCase(),
                        ))
                      pending,
                  ],
                ));
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(l10n.nutritionPlanGenerate),
            ),
          ],
        ),
      ),
    );
  }
}

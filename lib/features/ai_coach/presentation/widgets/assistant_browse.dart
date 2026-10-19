import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/catalog/assistant_catalog.dart';
import '../../domain/models/assistant_context.dart';
import '../../domain/services/assistant_phrasing.dart';
import '../providers/assistant_providers.dart';

IconData assistantCategoryIcon(String id) => switch (id) {
  'balanced' => Icons.restaurant_outlined,
  'weight_loss' => Icons.monitor_weight_outlined,
  'weight_maintain' => Icons.balance_outlined,
  'calories' => Icons.local_fire_department_outlined,
  'protein' => Icons.egg_outlined,
  'carbs' => Icons.grain_outlined,
  'fats' => Icons.water_drop_outlined,
  'fiber' => Icons.grass_outlined,
  'vitamins' => Icons.energy_savings_leaf_outlined,
  'portions' => Icons.pie_chart_outline,
  'high_protein' => Icons.fitness_center_outlined,
  'low_calorie' => Icons.eco_outlined,
  'vegetarian' => Icons.spa_outlined,
  'vegan' => Icons.yard_outlined,
  'produce' => Icons.apple_outlined,
  'salads' => Icons.brunch_dining_outlined,
  'soups' => Icons.soup_kitchen_outlined,
  'breakfast' => Icons.free_breakfast_outlined,
  'snacks' => Icons.cookie_outlined,
  'shopping' => Icons.shopping_basket_outlined,
  'water' => Icons.water_drop_outlined,
  'hunger' => Icons.lunch_dining_outlined,
  'sweets' => Icons.icecream_outlined,
  'night_eating' => Icons.nights_stay_outlined,
  'meal_pattern' => Icons.schedule_outlined,
  'emotional' => Icons.favorite_outline,
  'sleep' => Icons.bedtime_outlined,
  'stress' => Icons.self_improvement_outlined,
  'activity' => Icons.directions_walk_outlined,
  'sustainable' => Icons.autorenew,
  'bloating' => Icons.bubble_chart_outlined,
  'constipation' => Icons.health_and_safety_outlined,
  'reflux' => Icons.local_fire_department_outlined,
  'irritating_foods' => Icons.report_outlined,
  'microbiome' => Icons.bubble_chart_outlined,
  'intolerance' => Icons.no_food_outlined,
  'allergy' => Icons.warning_amber_outlined,
  'immunity' => Icons.health_and_safety_outlined,
  'bone' => Icons.accessibility_new_outlined,
  'heart' => Icons.favorite_outline,
  'glucose' => Icons.bloodtype_outlined,
  'cholesterol' => Icons.monitor_heart_outlined,
  'blood_pressure' => Icons.speed_outlined,
  'anemia' => Icons.water_outlined,
  'womens' => Icons.female_outlined,
  'menopause' => Icons.female_outlined,
  'pregnancy' => Icons.pregnant_woman_outlined,
  'children' => Icons.child_care_outlined,
  'older_adults' => Icons.elderly_outlined,
  'supplements' => Icons.medication_outlined,
  _ => Icons.chat_bubble_outline,
};

String assistantSectionTitle(AppLocalizations l10n, AssistantSection section) =>
    switch (section) {
      AssistantSection.diet => l10n.assistantSectionDiet,
      AssistantSection.foods => l10n.assistantSectionFoods,
      AssistantSection.habits => l10n.assistantSectionHabits,
      AssistantSection.digestion => l10n.assistantSectionDigestion,
      AssistantSection.special => l10n.assistantSectionSpecial,
    };

class AssistantBrowse extends ConsumerWidget {
  const AssistantBrowse({
    super.key,
    required this.query,
    required this.scrollController,
    required this.searchController,
    required this.categoryKey,
    required this.onQuery,
    required this.onOpenQuestion,
  });

  final String query;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final GlobalKey Function(String id) categoryKey;
  final ValueChanged<String> onQuery;
  final ValueChanged<AssistantQuestion> onOpenQuestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';
    final results = AssistantCatalog.search(query);

    return ListView(
      key: const ValueKey('assistant-catalog'),
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Text(
          l10n.assistantWelcome,
          key: const ValueKey('assistant-welcome'),
          style: context.textStyles.titleMedium,
        ),
        AppSpacing.gapLg,
        const _SummaryCard(),
        AppSpacing.gapLg,
        TextField(
          key: const ValueKey('assistant-search'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: onQuery,
          decoration: InputDecoration(
            hintText: l10n.assistantSearchHint,
            prefixIcon: Icon(
              Icons.search,
              semanticLabel: l10n.assistantSearchHint,
            ),
            isDense: true,
          ),
        ),
        AppSpacing.gapLg,
        if (results.isEmpty)
          Text(
            l10n.assistantSearchEmpty,
            key: const ValueKey('assistant-search-empty'),
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          )
        else
          for (final section in AssistantSection.values) ...[
            if (results.any(
              (category) =>
                  category.section == section &&
                  _questionsFor(category, query).isNotEmpty,
            )) ...[
              Text(
                assistantSectionTitle(l10n, section),
                key: ValueKey('assistant-section-${section.name}'),
                style: context.textStyles.titleSmall,
              ),
              AppSpacing.gapSm,
              for (final category in results)
                if (category.section == section &&
                    _questionsFor(category, query).isNotEmpty) ...[
                  Padding(
                    key: categoryKey(category.id),
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          assistantCategoryIcon(category.id),
                          color: context.colors.primary,
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Text(
                            turkish ? category.titleTr : category.titleEn,
                            key: ValueKey('assistant-category-${category.id}'),
                            style: context.textStyles.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXs,
                  for (final question in _questionsFor(category, query))
                    _QuestionRow(
                      question: question,
                      turkish: turkish,
                      onTap: () => onOpenQuestion(question),
                    ),
                ],
              AppSpacing.gapMd,
            ],
          ],
      ],
    );
  }
}

List<AssistantQuestion> _questionsFor(AssistantCategory category, String raw) {
  final query = AssistantPhrasing.prepared(raw);
  if (query.isEmpty || _categoryTextHits(category, query)) {
    return category.questions;
  }
  return [
    for (final question in category.questions)
      if (_hits('${question.tr} ${question.en}', query)) question,
  ];
}

bool _categoryTextHits(AssistantCategory category, String query) {
  final haystack = [
    category.titleTr,
    category.titleEn,
    category.descriptionTr,
    category.descriptionEn,
    ...category.keywords,
  ].join(' ');
  return _hits(haystack, query);
}

bool _hits(String haystack, String query) {
  final folded = AssistantPhrasing.prepared(haystack);
  if (query.length >= 3) return folded.contains(query);
  return folded.split(' ').contains(query);
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.question,
    required this.turkish,
    required this.onTap,
  });

  final AssistantQuestion question;
  final bool turkish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          key: ValueKey('assistant-question-${question.id}'),
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      turkish ? question.tr : question.en,
                      style: context.textStyles.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = ref.watch(assistantTodayProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.assistantSummaryTitle, style: context.textStyles.titleSmall),
          AppSpacing.gapSm,
          summary.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(l10n.assistantSummaryError),
            data: (contextData) => Text(_line(context, contextData)),
          ),
        ],
      ),
    );
  }

  String _line(BuildContext context, AssistantContext data) {
    final l10n = context.l10n;
    if (data.todayMeals.isEmpty) return l10n.assistantSummaryEmpty;
    final consumed = AppFormat.integer(context, data.consumed.calories);
    if (!data.hasPersonalTargets) return l10n.assistantSummaryNoTarget(consumed);
    final target = data.targets.calories;
    final gap = target - data.consumed.calories;
    if (gap >= 0) {
      return l10n.assistantSummaryCalories(
        consumed,
        AppFormat.integer(context, target),
        AppFormat.integer(context, gap),
      );
    }
    return l10n.assistantSummaryOver(
      consumed,
      AppFormat.integer(context, target),
      AppFormat.integer(context, -gap),
    );
  }
}

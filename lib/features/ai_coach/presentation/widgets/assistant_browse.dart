import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/catalog/assistant_catalog.dart';
import '../../domain/models/assistant_context.dart';
import '../providers/assistant_providers.dart';

IconData assistantCategoryIcon(String id) => switch (id) {
  'daily' => Icons.today_outlined,
  'calories' => Icons.local_fire_department_outlined,
  'macros' => Icons.pie_chart_outline,
  'breakfast' => Icons.free_breakfast_outlined,
  'main_meals' => Icons.restaurant_outlined,
  'snacks' => Icons.cookie_outlined,
  'recipes' => Icons.soup_kitchen_outlined,
  'swaps' => Icons.swap_horiz,
  'water' => Icons.water_drop_outlined,
  'weight' => Icons.monitor_weight_outlined,
  'planning' => Icons.calendar_month_outlined,
  'shopping' => Icons.shopping_basket_outlined,
  'eating_out' => Icons.storefront_outlined,
  'facts' => Icons.menu_book_outlined,
  'preferences' => Icons.tune,
  'weekly' => Icons.date_range_outlined,
  'well_living' => Icons.spa_outlined,
  'vitamins' => Icons.energy_savings_leaf_outlined,
  'digestion' => Icons.grass_outlined,
  'sleep' => Icons.bedtime_outlined,
  'energy' => Icons.bolt_outlined,
  'heart' => Icons.favorite_outline,
  'glucose' => Icons.bloodtype_outlined,
  'bone' => Icons.accessibility_new_outlined,
  'immunity' => Icons.health_and_safety_outlined,
  'emotional' => Icons.self_improvement_outlined,
  'metabolism' => Icons.insights_outlined,
  'womens' => Icons.female_outlined,
  _ => Icons.chat_bubble_outline,
};

class AssistantBrowse extends ConsumerWidget {
  const AssistantBrowse({
    super.key,
    required this.query,
    required this.openCategoryId,
    required this.searchController,
    required this.categoryKey,
    required this.onQuery,
    required this.onToggleCategory,
    required this.onQuick,
    required this.onAsk,
    required this.busy,
  });

  final String query;
  final String? openCategoryId;
  final TextEditingController searchController;
  final GlobalKey Function(String id) categoryKey;
  final ValueChanged<String> onQuery;
  final ValueChanged<String> onToggleCategory;
  final ValueChanged<String> onQuick;
  final ValueChanged<AssistantQuestion> onAsk;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final turkish = Localizations.localeOf(context).languageCode == 'tr';
    final results = AssistantCatalog.search(query);
    final suggested = query.trim().isEmpty
        ? AssistantCatalog.suggestedQuestions()
        : const <AssistantQuestion>[];

    return ListView(
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
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ActionChip(
              label: Text(l10n.assistantQuickDaily),
              onPressed: () => onQuick('daily'),
            ),
            ActionChip(
              label: Text(l10n.assistantQuickMeals),
              onPressed: () => onQuick('main_meals'),
            ),
            ActionChip(
              label: Text(l10n.assistantQuickWellness),
              onPressed: () => onQuick('well_living'),
            ),
            ActionChip(
              label: Text(l10n.assistantQuickWeek),
              onPressed: () => onQuick('weekly'),
            ),
          ],
        ),
        AppSpacing.gapLg,
        TextField(
          key: const ValueKey('assistant-search'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: onQuery,
          decoration: InputDecoration(
            hintText: l10n.assistantSearchHint,
            prefixIcon: const Icon(Icons.search),
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
        else ...[
          if (suggested.isNotEmpty) ...[
            Text(l10n.assistantSuggestedTitle, style: context.textStyles.titleSmall),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final question in suggested)
                  ActionChip(
                    label: Text(_prompt(question, turkish)),
                    onPressed: busy ? null : () => onAsk(question),
                  ),
              ],
            ),
            AppSpacing.gapLg,
          ],
          for (final section in AssistantSection.values) ...[
            if (results.any((category) => category.section == section)) ...[
              Text(
                section == AssistantSection.nutrition
                    ? l10n.assistantNutritionSection
                    : l10n.assistantWellnessSection,
                style: context.textStyles.titleSmall,
              ),
              AppSpacing.gapSm,
              for (final category in results)
                if (category.section == section) ...[
                  AppCard(
                    key: categoryKey(category.id),
                    onTap: () => onToggleCategory(category.id),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(assistantCategoryIcon(category.id), color: context.colors.primary),
                            AppSpacing.gapMd,
                            Expanded(
                              child: Text(
                                turkish ? category.titleTr : category.titleEn,
                                key: ValueKey('assistant-category-${category.id}'),
                                style: context.textStyles.titleSmall,
                              ),
                            ),
                            Icon(
                              openCategoryId == category.id
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                            ),
                          ],
                        ),
                        if (openCategoryId == category.id) ...[
                          AppSpacing.gapSm,
                          for (final question in category.questions)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: ValueKey('assistant-question-${question.id}'),
                                onPressed: busy ? null : () => onAsk(question),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(_prompt(question, turkish)),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.gapSm,
                ],
              AppSpacing.gapMd,
            ],
          ],
        ],
      ],
    );
  }

  static String _prompt(AssistantQuestion question, bool turkish) =>
      turkish ? question.tr : question.en;
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

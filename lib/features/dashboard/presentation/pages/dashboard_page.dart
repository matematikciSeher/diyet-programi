import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../meal_plans/presentation/providers/meal_plan_providers.dart';
import '../../../meals/presentation/providers/diary_providers.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../../domain/daily_dashboard.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/activity_card.dart';
import '../widgets/calorie_summary_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/nutrition_score_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/todays_meals_card.dart';
import '../widgets/todays_plan_card.dart';
import '../widgets/water_card.dart';

/// Uygulamanın ana ekranı: "Bugün ne yedim, ne kadar hakkım kaldı,
/// proteinim yeterli mi, su içtim mi, planım ne?" sorularının cevabı.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Bu genişliğin üzerinde içerik iki sütuna bölünür.
  static const _twoColumnWidth = 760.0;
  static const _wideMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AsyncValueView(
          value: dashboard,
          onRetry: () => _refresh(ref),
          data: (data) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: LayoutBuilder(
              builder: (context, constraints) => _DashboardBody(
                data: data,
                twoColumns: constraints.maxWidth >= _twoColumnWidth,
                maxWidth: constraints.maxWidth >= _twoColumnWidth
                    ? _wideMaxWidth
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    final plan = mealPlanForDayProvider(ref.read(dashboardDayProvider));
    ref
      ..invalidate(todayActivityProvider)
      ..invalidate(plan);
    await Future.wait([
      ref.read(todayActivityProvider.future),
      ref.read(plan.future),
    ]);
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.data,
    required this.twoColumns,
    this.maxWidth,
  });

  final DailyDashboard data;
  final bool twoColumns;
  final double? maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final header = DashboardHeader(
      now: ref.watch(clockProvider)(),
      name: data.userName,
      onProfileTap: () => context.go(AppRoutes.profile),
    );
    final calories = CalorieSummaryCard(
      consumed: data.consumed,
      targets: data.targets,
    );
    final quickActions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.dashboardQuickActions),
        const QuickActions(),
      ],
    );
    final water = WaterCard(
      glasses: data.waterGlasses,
      goalGlasses: data.waterGoalGlasses,
      waterMl: data.waterMl,
      goalMl: data.targets.waterMl,
      onAddGlass: () => _addWater(context, ref),
      onTap: () => context.push(AppRoutes.water),
    );
    final activity = ActivityCard(
      activity: data.activity,
      stepGoal: data.targets.steps,
      onTap: () => context.push(AppRoutes.activity),
    );
    final score = NutritionScoreCard(score: data.score);
    final meals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.dashboardMealsTitle,
          actionLabel: l10n.actionSeeAll,
          onAction: () {
            ref.read(diaryMealFilterProvider.notifier).clear();
            context.go(AppRoutes.diary);
          },
        ),
        TodaysMealsCard(
          dashboard: data,
          onAddFood: (type) => _addFood(context, type),
          onOpenMeal: (type) => _openMeal(context, ref, type),
        ),
      ],
    );
    final plan = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.dashboardPlanTitle,
          actionLabel: l10n.actionSeeAll,
          onAction: () => context.go(AppRoutes.plans),
        ),
        PremiumGate(
          feature: AppFeature.personalMealPlan,
          fallback: const PremiumLockedCard(
            feature: AppFeature.personalMealPlan,
          ),
          child: TodaysPlanCard(
            plan: data.plan,
            loggedMealTypes: data.meals.map((m) => m.mealType).toSet(),
            onOpenPlan: () => context.go(AppRoutes.plans),
          ),
        ),
      ],
    );

    const gap = SizedBox(height: AppSpacing.lg);
    final Widget content;
    if (twoColumns) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AppSpacing.gapXl,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [calories, gap, quickActions, gap, meals],
                ),
              ),
              AppSpacing.gapXl,
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [water, gap, score, gap, activity, gap, plan],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AppSpacing.gapXl,
          calories,
          gap,
          quickActions,
          gap,
          water,
          gap,
          score,
          gap,
          meals,
          gap,
          plan,
          gap,
          activity,
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl,
      ),
      child: ResponsiveCenter(
        maxWidth: maxWidth ?? Breakpoints.maxContentWidth,
        child: content,
      ),
    );
  }

  void _addFood(BuildContext context, MealType type) => context.push(
    AppRoutes.withMeal(AppRoutes.foodSearch, type, lockMeal: true),
  );

  void _openMeal(BuildContext context, WidgetRef ref, MealType type) {
    ref
      ..read(collapsedMealsProvider.notifier).expand(type)
      ..read(diaryMealFilterProvider.notifier).select(type);
    context.go(AppRoutes.diary);
  }

  Future<void> _addWater(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(dashboardActionsProvider);
    final l10n = context.l10n;
    unawaited(HapticFeedback.lightImpact());
    final result = await actions.addGlass();
    if (!context.mounted) return;
    result.when(
      success: (log) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.waterAdded(log.amountMl)),
              action: SnackBarAction(
                label: l10n.actionUndo,
                onPressed: () => actions.undoWater(log.id),
              ),
            ),
          );
      },
      failure: (f) => context.showSnack(f.localizedMessage(context)),
    );
  }
}

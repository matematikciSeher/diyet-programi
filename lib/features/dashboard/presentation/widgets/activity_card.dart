import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../activity/domain/models/daily_activity.dart';
import '../../../activity/presentation/activity_format.dart';
import 'card_title.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.stepGoal,
    this.onTap,
    this.title,
  });

  final DailyActivity activity;
  final int stepGoal;
  final VoidCallback? onTap;

  /// Verilmezse "Aktivite".
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.nutritionColors;
    final fromHealth = activity.source == ActivitySource.health;
    final stepProgress = !activity.stepsKnown || stepGoal <= 0
        ? 0.0
        : (activity.steps / stepGoal).clamp(0.0, 1.0);
    final third = fromHealth
        ? (
            icon: Icons.route_outlined,
            value: formatActivityDistance(
              context,
              activity.distanceMeters,
              known: activity.distanceKnown,
            ),
            label: l10n.activityDistance,
            color: c.carbs,
          )
        : (
            icon: Icons.timer_outlined,
            value: l10n.minutesValue(
              AppFormat.integer(context, activity.exerciseMinutes),
            ),
            label: l10n.activityExercise,
            color: c.protein,
          );

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.directions_walk_rounded,
            title: title ?? l10n.dashboardActivityTitle,
            color: c.fiber,
          ),
          AppSpacing.gapLg,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.directions_walk_rounded,
                  value: formatKnownMeasure(
                    context,
                    known: activity.stepsKnown,
                    value: AppFormat.integer(context, activity.steps),
                  ),
                  label: l10n.activitySteps,
                  color: c.fiber,
                ),
              ),
              Expanded(
                child: _Metric(
                  icon: Icons.local_fire_department_outlined,
                  value: formatKnownMeasure(
                    context,
                    known: activity.caloriesKnown,
                    value: AppFormat.integer(context, activity.activeCalories),
                  ),
                  label: l10n.activityActiveKcal,
                  color: c.calories,
                ),
              ),
              Expanded(
                child: _Metric(
                  icon: third.icon,
                  value: third.value,
                  label: third.label,
                  color: third.color,
                ),
              ),
            ],
          ),
          AppSpacing.gapLg,
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: LinearProgressIndicator(
                    value: stepProgress,
                    minHeight: 6,
                    color: c.fiber,
                    backgroundColor: c.fiber.withValues(alpha: 0.16),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              Text(
                l10n.stepsGoal(AppFormat.integer(context, stepGoal)),
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: color),
          AppSpacing.gapXs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

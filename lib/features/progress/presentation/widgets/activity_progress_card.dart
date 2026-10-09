import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../activity/domain/services/activity_health_mapper.dart';
import '../../../activity/presentation/activity_format.dart';
import '../../../activity/presentation/providers/health_link_providers.dart';
import '../../../dashboard/presentation/widgets/card_title.dart';

/// Günlük ve son 7 günün adım, mesafe ve aktif kalori özeti.
/// Mevcut kart düzenini kullanır; yeni grafik paketi yoktur.
class ActivityProgressCard extends ConsumerWidget {
  const ActivityProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final days = ref.watch(weeklyActivityProvider);
    final summary = days.maybeWhen(
      data: ActivityWeekSummary.fromDays,
      orElse: () => null,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardTitle(
            icon: Icons.directions_walk_rounded,
            title: l10n.progressActivityTitle,
            color: context.nutritionColors.fiber,
          ),
          AppSpacing.gapLg,
          if (summary == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _Line(
              label: l10n.progressActivityToday,
              value: formatKnownMeasure(
                context,
                known: summary.today.stepsKnown,
                value: AppFormat.integer(context, summary.today.steps),
              ),
            ),
            _Line(
              label: l10n.activityDistance,
              value: formatActivityDistance(
                context,
                summary.today.distanceMeters,
                known: summary.today.distanceKnown,
              ),
            ),
            _Line(
              label: l10n.activityActiveKcal,
              value: formatKnownMeasure(
                context,
                known: summary.today.caloriesKnown,
                value: AppFormat.integer(context, summary.today.activeCalories),
              ),
            ),
            const Divider(),
            _Line(
              label: l10n.progressActivityWeek,
              value: formatKnownMeasure(
                context,
                known: summary.weekStepsKnown,
                value: AppFormat.integer(context, summary.weekSteps),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: context.textStyles.bodyMedium),
          ),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

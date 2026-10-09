import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_view.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../../../fasting/domain/models/fasting_schedule.dart';
import '../../../fasting/presentation/providers/fasting_providers.dart';
import '../../../meal_plans/domain/models/meal_plan_preferences.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_settings.dart';
import '../providers/notification_providers.dart';

extension ReminderTypeL10n on ReminderType {
  String label(AppLocalizations l10n) => switch (this) {
    ReminderType.breakfast => l10n.reminderBreakfast,
    ReminderType.lunch => l10n.reminderLunch,
    ReminderType.snack => l10n.reminderSnack,
    ReminderType.dinner => l10n.reminderDinner,
    ReminderType.water => l10n.reminderWater,
    ReminderType.dailyGoal => l10n.reminderDailyGoal,
    ReminderType.weighIn => l10n.reminderWeighIn,
    ReminderType.fastingStart => l10n.reminderFastingStart,
    ReminderType.eatingWindowStart => l10n.reminderEatingStart,
    ReminderType.eatingWindowEnd => l10n.reminderEatingEnd,
    ReminderType.fastingEnd => l10n.reminderFastingEnd,
    ReminderType.motivation => l10n.reminderMotivation,
    ReminderType.plannedMeal => l10n.reminderPlan,
  };
}

extension ReminderGroupL10n on ReminderGroup {
  String label(AppLocalizations l10n) => switch (this) {
    ReminderGroup.meal => l10n.reminderGroupMeal,
    ReminderGroup.water => l10n.reminderGroupWater,
    ReminderGroup.goal => l10n.reminderGroupGoal,
    ReminderGroup.fasting => l10n.reminderGroupFasting,
    ReminderGroup.motivation => l10n.reminderGroupMotivation,
    ReminderGroup.plan => l10n.reminderGroupPlan,
  };
}

/// Öğün, su, hedef, oruç ve motivasyon hatırlatmalarının ayar merkezi.
/// Her değişiklik kaydedilir ve planlanmış bildirimler yeniden yazılır.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    Future<Result<bool>> Function() action,
  ) async {
    final result = await action();
    if (!context.mounted) return;
    switch (result) {
      case Success(value: false):
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.notificationsPermissionDenied),
              action: SnackBarAction(
                label: context.l10n.notificationsOpenSettings,
                onPressed: () => ref
                    .read(notificationSettingsControllerProvider)
                    .openSystemSettings(),
              ),
            ),
          );
      case Success():
        break;
      case Err(:final failure):
        context.showSnack(failure.localizedMessage(context));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(notificationSettingsProvider);
    final controller = ref.read(notificationSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureNotifications)),
      body: AsyncValueView(
        value: settings,
        loading: (_) => const SkeletonView(),
        onRetry: () => ref.invalidate(notificationSettingsProvider),
        data: (s) => ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      key: const ValueKey('notifications-master'),
                      value: s.enabled,
                      onChanged: (on) => _apply(
                        context,
                        ref,
                        () => controller.setEnabled(enabled: on),
                      ),
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: Text(l10n.notificationsMaster),
                      subtitle: Text(
                        s.enabled
                            ? l10n.notificationsScheduledCount(
                                ref.watch(plannedRemindersProvider).length,
                              )
                            : l10n.notificationsMasterOff,
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  _SleepHoursCard(settings: s),
                  for (final group in ReminderGroup.values)
                    _GroupSection(group: group, settings: s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSection extends ConsumerWidget {
  const _GroupSection({required this.group, required this.settings});

  final ReminderGroup group;
  final NotificationSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(fastingScheduleProvider);
    final slots = MealPlanPreferences.fromProfile(
      ref.watch(userProfileProvider).value,
    ).slots.toSet();
    final types = [
      for (final type in ReminderType.inGroup(group))
        if (type.mealType == null || slots.contains(type.mealType)) type,
    ];
    if (types.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: group.label(l10n).toUpperCase()),
        if (group == ReminderGroup.fasting && schedule == null)
          AppCard(
            onTap: () => context.push(AppRoutes.fasting),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined),
                AppSpacing.gapMd,
                Expanded(child: Text(l10n.notificationsFastingNeedsProtocol)),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, type) in types.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  _ReminderTile(
                    type: type,
                    setting: settings[type],
                    masterEnabled: settings.enabled,
                    schedule: schedule,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({
    required this.type,
    required this.setting,
    required this.masterEnabled,
    required this.schedule,
  });

  final ReminderType type;
  final ReminderSetting setting;
  final bool masterEnabled;
  final FastingSchedule? schedule;

  /// Oruç hatırlatmalarının saati protokolden hesaplanır.
  int? _autoMinutes() {
    final s = schedule;
    if (s == null) return null;
    return switch (type) {
      ReminderType.fastingStart => s.fastingStartMinutes,
      ReminderType.eatingWindowStart => s.eatingStartMinutes,
      ReminderType.eatingWindowEnd =>
        s.eatingEndMinutes - NotificationSettings.eatingWindowEndLeadMinutes,
      _ => null,
    };
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final minutes = setting.minutes ?? type.defaultMinutes!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !context.mounted) return;
    await NotificationsPage._apply(
      context,
      ref,
      () => ref
          .read(notificationSettingsControllerProvider)
          .setTime(type, picked.hour * 60 + picked.minute),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(notificationSettingsControllerProvider);
    final minutes = setting.minutes ?? type.defaultMinutes;
    final auto = _autoMinutes();
    final outsideWindow =
        type.group == ReminderGroup.meal &&
        schedule != null &&
        minutes != null &&
        !schedule!.isInEatingWindow(minutes);

    final subtitle = switch (type) {
      ReminderType.water => l10n.reminderWaterBalanced,
      ReminderType.plannedMeal => l10n.reminderPlanHint,
      ReminderType.weighIn => l10n.reminderWeeklyMonday(
        AppFormat.minutesOfDay(context, minutes!),
      ),
      ReminderType.fastingEnd => l10n.reminderFastingEndHint,
      _ when auto != null => AppFormat.minutesOfDay(context, auto),
      _ when outsideWindow => l10n.reminderOutsideWindow,
      _ => null,
    };

    return Column(
      children: [
        SwitchListTile(
          key: ValueKey('reminder-${type.name}'),
          value: setting.enabled,
          onChanged: masterEnabled
              ? (on) => NotificationsPage._apply(
                  context,
                  ref,
                  () => controller.toggle(type, enabled: on),
                )
              : null,
          title: Text(type.label(l10n)),
          subtitle: subtitle == null ? null : Text(subtitle),
        ),
        if (type.hasTime && setting.enabled && masterEnabled)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(AppFormat.minutesOfDay(context, minutes!)),
                  tooltip: l10n.reminderChangeTime,
                  onPressed: () => _pickTime(context, ref),
                ),
                if (type == ReminderType.water) ...[
                  AppSpacing.gapSm,
                  DropdownButton<int>(
                    value:
                        setting.intervalMinutes ??
                        NotificationSettings.defaultWaterIntervalMinutes,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final m in NotificationSettings.waterIntervals)
                        DropdownMenuItem(
                          value: m,
                          child: Text(
                            l10n.reminderEveryHours(
                              AppFormat.decimal(context, m / 60),
                            ),
                          ),
                        ),
                    ],
                    onChanged: (m) {
                      if (m == null) return;
                      NotificationsPage._apply(
                        context,
                        ref,
                        () => controller.setWaterInterval(m),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SleepHoursCard extends ConsumerWidget {
  const _SleepHoursCard({required this.settings});

  final NotificationSettings settings;

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required bool start,
  }) async {
    final minutes = start
        ? settings.sleepStartMinutes
        : settings.sleepEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null || !context.mounted) return;
    final value = picked.hour * 60 + picked.minute;
    await NotificationsPage._apply(
      context,
      ref,
      () => ref
          .read(notificationSettingsControllerProvider)
          .setSleepHours(
            startMinutes: start ? value : settings.sleepStartMinutes,
            endMinutes: start ? settings.sleepEndMinutes : value,
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.sleepHoursTitle, style: context.textStyles.titleSmall),
          AppSpacing.gapXs,
          Text(
            l10n.sleepHoursHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                key: const ValueKey('sleep-start'),
                avatar: const Icon(Icons.bedtime_outlined, size: 18),
                label: Text(
                  '${l10n.sleepStart}: ${AppFormat.minutesOfDay(context, settings.sleepStartMinutes)}',
                ),
                onPressed: () => _pick(context, ref, start: true),
              ),
              ActionChip(
                key: const ValueKey('sleep-end'),
                avatar: const Icon(Icons.wb_sunny_outlined, size: 18),
                label: Text(
                  '${l10n.sleepEnd}: ${AppFormat.minutesOfDay(context, settings.sleepEndMinutes)}',
                ),
                onPressed: () => _pick(context, ref, start: false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

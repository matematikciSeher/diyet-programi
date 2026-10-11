import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/legal/privacy_policy_link.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../../shared/services/subscription/subscription_service.dart';
import '../../../activity/presentation/widgets/health_data_section.dart';
import '../../../subscription/presentation/providers/premium_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final service = ref.watch(subscriptionServiceProvider);
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.featureSettings)),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(title: l10n.settingsTheme),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selection.first),
              ),
              AppSpacing.gapXl,
              SectionHeader(title: l10n.healthDataTitle),
              const HealthDataSection(),
              AppSpacing.gapXl,
              SectionHeader(title: l10n.settingsSubscription),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restore_rounded),
                title: Text(l10n.paywallRestore),
                onTap: () => _restore(context, ref),
              ),
              if (kDebugMode && service is TestMembershipControls)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l10n.testPremiumReset),
                  onTap: () =>
                      (service as TestMembershipControls).resetTestMembership(),
                ),
              AppSpacing.gapXl,
              SectionHeader(title: l10n.settingsLegal),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.settingsPrivacyPolicy),
                onTap: () => _openPrivacyPolicy(context, config),
              ),
              AppSpacing.gapXl,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy(
    BuildContext context,
    AppConfig config,
  ) async {
    final opened = await PrivacyPolicyLink.open(config);
    if (!context.mounted || opened) return;
    context.showSnack(context.l10n.settingsPrivacyPolicyUnavailable);
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref.read(subscriptionActionsProvider).restore();
    if (!context.mounted) return;
    context.showSnack(switch (result) {
      Success(:final value) when value.hasEntitlement(Entitlements.premium) =>
        l10n.paywallRestored,
      Success() => l10n.paywallNothingToRestore,
      Err(:final failure) => failure.localizedMessage(context),
    });
  }
}

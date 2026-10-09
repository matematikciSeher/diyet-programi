import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_messages.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../authentication/data/repositories/auth_repository_impl.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/presentation/providers/premium_providers.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  var _busy = false;
  var _deleting = false;

  Future<void> _deleteAccount() async {
    if (_busy) return;
    _busy = true;
    try {
      final confirmed = await showAppConfirmDialog(
        context,
        title: context.l10n.deleteAccountTitle,
        message: context.l10n.deleteAccountMessage,
        confirmLabel: context.l10n.actionDeleteAccount,
      );
      if (!confirmed || !mounted) return;
      setState(() => _deleting = true);
      final result = await ref.read(authRepositoryProvider).deleteAccount();
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (failure) =>
            context.showSnack(failure.localizedMessage(context)),
      );
    } finally {
      _busy = false;
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPremium = ref.watch(isPremiumProvider);
    final user = ref.watch(authStateProvider).value;
    final entries = <(String, IconData, String, AppFeature?)>[
      (
        l10n.featurePersonalInfo,
        Icons.person_outline_rounded,
        AppRoutes.personalInfo,
        null,
      ),
      (
        l10n.featureNutrition,
        Icons.pie_chart_outline_rounded,
        AppRoutes.nutritionPlan,
        null,
      ),
      (
        l10n.featureWeight,
        Icons.monitor_weight_outlined,
        AppRoutes.weight,
        null,
      ),
      (
        l10n.featureMeasurements,
        Icons.straighten_rounded,
        AppRoutes.measurements,
        null,
      ),
      (
        l10n.featureRecipes,
        Icons.soup_kitchen_outlined,
        AppRoutes.recipes,
        null,
      ),
      (
        l10n.featureFasting,
        Icons.timer_outlined,
        AppRoutes.fasting,
        AppFeature.fasting,
      ),
      (
        l10n.featureAiCoach,
        Icons.auto_awesome_outlined,
        AppRoutes.aiCoach,
        AppFeature.aiCoach,
      ),
      (
        l10n.featureNotifications,
        Icons.notifications_none_rounded,
        AppRoutes.notifications,
        null,
      ),
      (l10n.featureSettings, Icons.settings_outlined, AppRoutes.settings, null),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.featureProfile),
        bottom: _deleting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          ResponsiveCenter(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (user != null)
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(
                      user.displayName?.trim().isNotEmpty == true
                          ? user.displayName!
                          : user.email ?? l10n.signInGuestAccount,
                    ),
                    subtitle:
                        user.email != null &&
                            user.displayName?.trim().isNotEmpty == true
                        ? Text(user.email!)
                        : user.isAnonymous
                        ? Text(l10n.signInGuestAccount)
                        : null,
                  ),
                ListTile(
                  leading: Icon(
                    Icons.workspace_premium_outlined,
                    color: context.colors.primary,
                  ),
                  title: Text(l10n.featurePremium),
                  subtitle: Text(
                    isPremium
                        ? l10n.paywallActiveTitle
                        : l10n.premiumProfileSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openPaywall(context),
                ),
                for (final (label, icon, route, feature) in entries)
                  ListTile(
                    leading: Icon(icon),
                    title: Text(label),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (feature != null &&
                            !ref.watch(featureAccessProvider(feature))) ...[
                          const PremiumBadge(),
                          AppSpacing.gapSm,
                        ],
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.push(route),
                  ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: context.colors.error,
                  ),
                  title: Text(
                    l10n.actionSignOut,
                    style: TextStyle(color: context.colors.error),
                  ),
                  onTap: _deleting
                      ? null
                      : () => ref.read(authRepositoryProvider).signOut(),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: context.colors.error,
                  ),
                  title: Text(
                    l10n.actionDeleteAccount,
                    style: TextStyle(color: context.colors.error),
                  ),
                  trailing: _deleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _deleting ? null : _deleteAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

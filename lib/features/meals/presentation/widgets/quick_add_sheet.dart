import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/presentation/providers/premium_providers.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';

/// Hızlı ekleme seçenekleri. Seçimin nasıl yürütüleceğine sayfa karar verir;
/// böylece bir seçenek gerçek özelliğe (kamera, barkod, ses, sağlık)
/// bağlandığında yalnızca işleyici değişir.
enum DiaryQuickAction {
  food(Icons.restaurant_rounded),
  photo(
    Icons.photo_camera_outlined,
    premiumFeature: AppFeature.photoFoodAnalysis,
  ),
  barcode(Icons.qr_code_scanner_rounded),
  voice(Icons.mic_none_rounded),
  water(Icons.water_drop_outlined),
  weight(Icons.monitor_weight_outlined),
  activity(Icons.directions_run_rounded);

  const DiaryQuickAction(this.icon, {this.premiumFeature});

  final IconData icon;
  final AppFeature? premiumFeature;

  String label(AppLocalizations l10n) => switch (this) {
    food => l10n.quickAddFood,
    photo => l10n.quickAddPhoto,
    barcode => l10n.quickAddBarcode,
    voice => l10n.quickAddVoice,
    water => l10n.diaryAddWater,
    weight => l10n.diaryAddWeight,
    activity => l10n.diaryAddActivity,
  };
}

Future<DiaryQuickAction?> showQuickAddSheet(BuildContext context) =>
    showModalBottomSheet<DiaryQuickAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QuickAddSheet(),
    );

class _QuickAddSheet extends ConsumerWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.diaryQuickAddTitle,
            style: context.textStyles.titleLarge,
          ),
          AppSpacing.gapLg,
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = switch (constraints.maxWidth) {
                >= 480 => 4,
                >= 260 => 3,
                _ => 2,
              };
              final width =
                  (constraints.maxWidth - (columns - 1) * AppSpacing.sm) /
                  columns;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final action in DiaryQuickAction.values)
                    SizedBox(
                      width: width,
                      child: _QuickAddTile(
                        action: action,
                        locked:
                            action.premiumFeature != null &&
                            !ref.watch(
                              featureAccessProvider(action.premiumFeature!),
                            ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  const _QuickAddTile({required this.action, required this.locked});

  final DiaryQuickAction action;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = action.label(l10n);
    final primary = action == DiaryQuickAction.food;

    return Semantics(
      button: true,
      label: locked ? '$label, ${l10n.featurePremium}' : label,
      excludeSemantics: true,
      child: Material(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () => Navigator.of(context).pop(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.xs,
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primary
                          ? context.colors.primary
                          : context.colors.secondaryContainer,
                      foregroundColor: primary
                          ? context.colors.onPrimary
                          : context.colors.onSecondaryContainer,
                      child: Icon(action.icon),
                    ),
                    if (locked)
                      const PositionedDirectional(
                        top: -4,
                        end: -8,
                        child: PremiumBadge(compact: true),
                      ),
                  ],
                ),
                AppSpacing.gapSm,
                Text(
                  label,
                  style: context.textStyles.labelMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

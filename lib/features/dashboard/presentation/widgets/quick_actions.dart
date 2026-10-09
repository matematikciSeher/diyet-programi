import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../subscription/domain/models/app_feature.dart';
import '../../../subscription/presentation/providers/premium_providers.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';

/// Kayıt eklemenin dört hızlı yolu.
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = [
      (Icons.add_rounded, l10n.quickAddFood, AppRoutes.foodSearch, null),
      (
        Icons.photo_camera_outlined,
        l10n.quickAddPhoto,
        AppRoutes.photoLog,
        AppFeature.photoFoodAnalysis,
      ),
      (
        Icons.qr_code_scanner_rounded,
        l10n.quickAddBarcode,
        AppRoutes.barcodeScanner,
        null,
      ),
      (Icons.mic_none_rounded, l10n.quickAddVoice, AppRoutes.voiceLog, null),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, (icon, label, route, feature))
            in actions.indexed) ...[
          if (index > 0) AppSpacing.gapSm,
          Expanded(
            child: _QuickActionButton(
              icon: icon,
              label: label,
              primary: index == 0,
              locked:
                  feature != null && !ref.watch(featureAccessProvider(feature)),
              onTap: () => context.push(route),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.locked = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = primary ? colors.primary : colors.secondaryContainer;
    final foreground = primary ? colors.onPrimary : colors.onSecondaryContainer;

    return Semantics(
      button: true,
      label: locked ? '$label, ${context.l10n.featurePremium}' : label,
      excludeSemantics: true,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: background,
                borderRadius: AppRadius.lgAll,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.lgAll,
                  child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: Icon(icon, color: foreground),
                  ),
                ),
              ),
              if (locked)
                const PositionedDirectional(
                  top: AppSpacing.xs,
                  end: AppSpacing.xs,
                  child: IgnorePointer(child: PremiumBadge(compact: true)),
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
    );
  }
}

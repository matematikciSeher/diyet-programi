import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/datasources/food_api_config.dart';

/// Open Food Facts ODbL atfı. URL [FoodApiConfig] üzerinden tek yerde tutulur.
class OpenFoodFactsAttribution extends StatelessWidget {
  const OpenFoodFactsAttribution({super.key, this.compact = false});

  final bool compact;

  static Future<void> openHome() async {
    final uri = Uri.parse(FoodApiConfig.attributionUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Column(
      children: [
        Semantics(
          link: true,
          label: l10n.foodAttributionOffLink,
          button: true,
          child: TextButton(
            onPressed: openHome,
            child: Text(l10n.foodAttributionOffLink),
          ),
        ),
        Text(
          l10n.foodAttributionOffLicense,
          style: muted,
          textAlign: TextAlign.center,
        ),
        if (!compact) ...[
          AppSpacing.gapXs,
          Text(
            l10n.foodAttributionOff,
            style: muted,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

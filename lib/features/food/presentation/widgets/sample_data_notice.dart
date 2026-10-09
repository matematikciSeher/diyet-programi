import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Örnek (demo) besin verisi kullanıldığını açıkça belirtir.
class SampleDataNotice extends StatelessWidget {
  const SampleDataNotice({super.key, required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.tertiaryContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppSizes.iconSm,
            color: context.colors.onTertiaryContainer,
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              context.l10n.foodSampleDataNotice(source),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

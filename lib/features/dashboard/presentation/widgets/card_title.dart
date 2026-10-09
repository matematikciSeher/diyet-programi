import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Dashboard kartlarının üst satırı: renkli ikon, başlık, sağda ek bilgi.
class CardTitle extends StatelessWidget {
  const CardTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // Dar ekranda sağdaki bilgi başlığın altına kayar.
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconSm + 2, color: color),
              AppSpacing.gapSm,
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.textStyles.titleSmall),
                ),
              ),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

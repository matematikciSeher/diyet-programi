import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/extensions/context_extensions.dart';
import 'responsive_center.dart';

/// İçerik yüklenirken kart düzenini taklit eden sabit iskelet.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.height = 16, this.width, this.radius});

  final double height;
  final double? width;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: radius ?? AppRadius.smAll,
      ),
    );
  }
}

class SkeletonView extends StatelessWidget {
  const SkeletonView({super.key, this.cards = 3, this.cardHeight = 120});

  final int cards;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: ExcludeSemantics(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          children: [
            ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SkeletonBox(height: 24, width: 180),
                  AppSpacing.gapLg,
                  for (var i = 0; i < cards; i++) ...[
                    SkeletonBox(height: cardHeight, radius: AppRadius.lgAll),
                    AppSpacing.gapMd,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

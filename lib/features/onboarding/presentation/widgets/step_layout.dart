import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Tek bir soruya odaklanan ekranın başlık + içerik düzeni.
class StepLayout extends StatelessWidget {
  const StepLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.optional = false,
  });

  final String title;
  final String? subtitle;
  final bool optional;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (optional) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: context.colors.secondaryContainer,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                context.l10n.onboardingOptional,
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
          AppSpacing.gapMd,
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (subtitle != null) ...[
          AppSpacing.gapSm,
          Text(
            subtitle!,
            style: context.textStyles.bodyLarge?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        AppSpacing.gapXl,
        child,
      ],
    );
  }
}

/// Doğrulama hatası veya bilgi notu için küçük satır.
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.isError = true,
    this.icon,
  });

  final String message;
  final bool isError;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? context.colors.error
        : context.nutritionColors.warning;
    return Semantics(
      liveRegion: isError,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ??
                (isError
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded),
            size: AppSizes.iconSm,
            color: color,
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text }

/// Uygulama genelinde tutarlı buton. Yükleme durumunda tekrar tıklamayı
/// engeller ve ekran okuyuculara durum bildirir.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Text(label);
    final iconWidget = (icon == null || isLoading)
        ? null
        : Icon(icon, size: AppSizes.iconSm);

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        iconWidget == null
            ? FilledButton(onPressed: effectiveOnPressed, child: child)
            : FilledButton.icon(
                onPressed: effectiveOnPressed,
                icon: iconWidget,
                label: child,
              ),
      AppButtonVariant.secondary =>
        iconWidget == null
            ? OutlinedButton(onPressed: effectiveOnPressed, child: child)
            : OutlinedButton.icon(
                onPressed: effectiveOnPressed,
                icon: iconWidget,
                label: child,
              ),
      AppButtonVariant.text =>
        iconWidget == null
            ? TextButton(onPressed: effectiveOnPressed, child: child)
            : TextButton.icon(
                onPressed: effectiveOnPressed,
                icon: iconWidget,
                label: child,
              ),
    };

    return Semantics(
      button: true,
      label: isLoading ? label : null,
      liveRegion: isLoading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

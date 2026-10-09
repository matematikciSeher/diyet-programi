import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Tek soruluk ekranlarda kullanılan seçilebilir kart.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// [icon] yerine özel bir öncü widget (ör. büyük rakam).
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor = selected ? colors.primary : colors.outlineVariant;
    final background = selected
        ? colors.primaryContainer.withValues(alpha: 0.55)
        : colors.surfaceContainerLow;

    final leadingWidget =
        leading ??
        (icon == null
            ? null
            : Icon(
                icon,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ));

    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    if (leadingWidget != null) ...[
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.surface
                              : colors.surfaceContainerHighest,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: leadingWidget,
                      ),
                      AppSpacing.gapLg,
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              subtitle!,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AppSpacing.gapSm,
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(selected),
                        color: selected ? colors.primary : colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bir enum'ın değerlerini [OptionTile] listesi olarak gösterir.
class OptionList<T> extends StatelessWidget {
  const OptionList({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
    required this.titleOf,
    this.subtitleOf,
    this.iconOf,
    this.leadingOf,
  });

  final List<T> values;
  final T? selected;
  final ValueChanged<T> onSelected;
  final String Function(T value) titleOf;
  final String? Function(T value)? subtitleOf;
  final IconData? Function(T value)? iconOf;
  final Widget? Function(T value, {required bool selected})? leadingOf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final value in values) ...[
          OptionTile(
            title: titleOf(value),
            subtitle: subtitleOf?.call(value),
            icon: iconOf?.call(value),
            leading: leadingOf?.call(value, selected: value == selected),
            selected: value == selected,
            onTap: () => onSelected(value),
          ),
          if (value != values.last) AppSpacing.gapMd,
        ],
      ],
    );
  }
}

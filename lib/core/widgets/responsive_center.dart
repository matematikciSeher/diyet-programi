import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/breakpoints.dart';

/// İçeriği geniş ekranlarda ortalar ve okunabilir genişlikte sınırlar.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding = AppSpacing.page,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Pencere boyutuna göre farklı yerleşim döndürür.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  final WidgetBuilder compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (Breakpoints.fromWidth(constraints.maxWidth)) {
          WindowSize.expanded => (expanded ?? medium ?? compact)(context),
          WindowSize.medium => (medium ?? compact)(context),
          WindowSize.compact => compact(context),
        };
      },
    );
  }
}

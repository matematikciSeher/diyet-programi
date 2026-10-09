import 'package:flutter/widgets.dart';

/// Material 3 pencere boyutu sınıfları.
enum WindowSize { compact, medium, expanded }

abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// İçerik sütununun tablet/geniş ekranlardaki azami genişliği.
  static const double maxContentWidth = 720;

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static WindowSize fromWidth(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }
}

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme_extensions.dart';
import '../breakpoints.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  NutritionColors get nutritionColors =>
      Theme.of(this).extension<NutritionColors>()!;

  AppLocalizations get l10n => AppLocalizations.of(this);

  WindowSize get windowSize => Breakpoints.of(this);
  bool get isCompact => windowSize == WindowSize.compact;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

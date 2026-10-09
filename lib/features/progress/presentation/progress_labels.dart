import 'package:flutter/material.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/presentation/enum_labels.dart';
import '../domain/models/progress_report.dart';

extension MeasurementFieldL10n on MeasurementField {
  String label(AppLocalizations l10n) => switch (this) {
    MeasurementField.waist => l10n.measureWaist,
    MeasurementField.hip => l10n.measureHip,
    MeasurementField.chest => l10n.measureChest,
    MeasurementField.neck => l10n.measureNeck,
    MeasurementField.arm => l10n.measureArm,
    MeasurementField.thigh => l10n.measureThigh,
    MeasurementField.bodyFat => l10n.measureBodyFat,
  };

  String unit(AppLocalizations l10n) =>
      this == MeasurementField.bodyFat ? '%' : l10n.unitCm;

  String format(BuildContext context, double value) {
    final text = AppFormat.decimal(context, value);
    return this == MeasurementField.bodyFat
        ? context.l10n.progressPercent(text)
        : context.l10n.progressCm(text);
  }

  /// Seçili alanın makul giriş aralığı (cm veya %).
  (double, double) get validRange => switch (this) {
    MeasurementField.bodyFat => (2, 70),
    MeasurementField.neck || MeasurementField.arm => (10, 80),
    MeasurementField.thigh => (20, 120),
    _ => (30, 250),
  };
}

extension ProgressRangeL10n on ProgressRange {
  String label(AppLocalizations l10n) => l10n.progressRange(name);
}

abstract final class ProgressFormat {
  static String kg(BuildContext context, double value) =>
      context.l10n.progressKg(AppFormat.decimal(context, value));

  /// Artışı `+`, azalışı `−` ile gösterir (ör. "+0,4", "−1,2").
  static String signed(BuildContext context, double value, {int digits = 1}) {
    final rounded = double.parse(value.toStringAsFixed(digits));
    final text = AppFormat.decimal(context, rounded.abs(), digits: digits);
    if (rounded > 0) return '+$text';
    if (rounded < 0) return '−$text';
    return text;
  }

  static String shortDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatShortMonthDay(date);

  /// Hem "72,5" hem "72.5" kabul edilir.
  static double? parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
}

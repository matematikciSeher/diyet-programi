import 'package:flutter/widgets.dart';

import '../../../core/utils/extensions/context_extensions.dart';
import '../../../shared/presentation/enum_labels.dart';

String formatActivityDistance(
  BuildContext context,
  double? meters, {
  required bool known,
}) {
  if (!known || meters == null) return context.l10n.healthValueUnavailable;
  if (meters >= 1000) {
    return context.l10n.activityDistanceKm(
      AppFormat.decimal(context, meters / 1000, digits: 2),
    );
  }
  return context.l10n.activityDistanceMeters(
    AppFormat.integer(context, meters),
  );
}

String formatKnownMeasure(
  BuildContext context, {
  required bool known,
  required String value,
}) => known ? value : context.l10n.healthValueUnavailable;

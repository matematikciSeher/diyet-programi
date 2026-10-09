import 'package:flutter/widgets.dart';

import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/presentation/enum_labels.dart';
import '../../domain/onboarding_validator.dart';

extension OnboardingValidationErrorText on OnboardingValidationError {
  String message(BuildContext context) {
    final l10n = context.l10n;
    String fmt(num? v) => v == null ? '' : AppFormat.decimal(context, v);
    return switch (type) {
      OnboardingErrorType.selectionRequired => l10n.errorSelectOption,
      OnboardingErrorType.valueRequired => l10n.errorValueRequired,
      OnboardingErrorType.outOfRange => l10n.errorOutOfRange(
        fmt(min),
        fmt(max),
      ),
      OnboardingErrorType.targetMustBeBelowCurrent =>
        l10n.errorTargetBelowCurrent,
      OnboardingErrorType.targetMustBeAboveCurrent =>
        l10n.errorTargetAboveCurrent,
      OnboardingErrorType.targetBelowHealthyWeight =>
        l10n.errorTargetBelowHealthy(fmt(min)),
      OnboardingErrorType.targetDateInPast => l10n.errorTargetDatePast,
    };
  }
}

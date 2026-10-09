import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../utils/extensions/context_extensions.dart';
import 'failures.dart';

extension FailureMessages on Failure {
  /// Kullanıcıya gösterilecek yerelleştirilmiş mesaj. Teknik detaylar
  /// (`message`, `cause`) kullanıcıya gösterilmez, loglanır.
  String localizedMessage(BuildContext context) {
    final l10n = context.l10n;
    final capture = _captureMessage(l10n, code ?? message);
    if (capture != null) return capture;
    return switch (this) {
      NetworkFailure() => l10n.errorNetwork,
      PermissionFailure() => l10n.errorPermission,
      PurchaseFailure() => l10n.errorPurchase,
      SubscriptionRequiredFailure() => l10n.errorPremiumRequired,
      NotImplementedFailure() => l10n.errorServiceUnavailable,
      AuthFailure(:final code, :final message) => _authMessage(
        l10n,
        code: code,
        message: message,
      ),
      _ => l10n.errorGeneric,
    };
  }

  String? _captureMessage(AppLocalizations l10n, String? code) {
    return switch (code) {
      'AI_SERVICE_NOT_CONFIGURED' => l10n.captureErrorNotConfigured,
      'timeout' => l10n.captureErrorTimeout,
      'no_connection' => l10n.captureErrorOffline,
      'rate_limited' => l10n.captureErrorRateLimited,
      'invalid_response' => l10n.captureErrorInvalid,
      'empty_response' => l10n.captureErrorEmpty,
      'malformed_response' => l10n.captureErrorMalformed,
      'unavailable' => l10n.captureErrorUnavailable,
      'image_too_large' => l10n.captureErrorImageTooLarge,
      'unsupported_image' => l10n.captureErrorUnsupportedImage,
      'permission_denied' => l10n.errorPermission,
      'speech_unavailable' => l10n.captureErrorSpeechUnavailable,
      'transcription_failed' => l10n.captureErrorTranscription,
      'ambiguous_food' => l10n.captureErrorAmbiguous,
      'food_not_found' => l10n.captureErrorNotFound,
      'confirmation_required' => l10n.captureErrorConfirmation,
      'duplicate_request' => l10n.captureErrorDuplicate,
      'allergy_conflict' => l10n.captureErrorAllergy,
      'meal_required' => l10n.photoLogSelectMeal,
      _ => null,
    };
  }

  String _authMessage(
    AppLocalizations l10n, {
    required String? code,
    required String message,
  }) {
    return switch (code ?? message) {
      'invalid_email' || 'invalid-email' => l10n.authInvalidEmail,
      'invalid_credentials' ||
      'wrong-password' ||
      'invalid-credential' ||
      'user-not-found' => l10n.authInvalidCredentials,
      'email_already_in_use' || 'email-already-in-use' => l10n.authEmailInUse,
      'weak_password' || 'weak-password' => l10n.authWeakPassword,
      'too_many_requests' || 'too-many-requests' => l10n.authTooManyRequests,
      'requires_recent_login' ||
      'requires-recent-login' => l10n.authRequiresRecentLogin,
      'cancelled' || 'aborted' => l10n.authCancelled,
      'network_unavailable' || 'network-request-failed' => l10n.errorNetwork,
      _ => l10n.errorGeneric,
    };
  }
}

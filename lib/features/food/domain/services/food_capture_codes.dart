import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failures.dart';

/// Fotoğraf ve ses yakalama hataları. Yeni bir hata hiyerarşisi değildir;
/// mevcut [Failure] türlerinin `code` / `message` alanına yazılır.
abstract final class FoodCaptureCodes {
  static const notConfigured = 'AI_SERVICE_NOT_CONFIGURED';
  static const offline = 'no_connection';
  static const timeout = 'timeout';
  static const rateLimited = 'rate_limited';
  static const invalidResponse = 'invalid_response';
  static const emptyResponse = 'empty_response';
  static const malformed = 'malformed_response';
  static const unavailable = 'unavailable';
  static const imageTooLarge = 'image_too_large';
  static const unsupportedImage = 'unsupported_image';
  static const permissionDenied = 'permission_denied';
  static const speechUnavailable = 'speech_unavailable';
  static const transcriptionFailed = 'transcription_failed';
  static const ambiguousFood = 'ambiguous_food';
  static const foodNotFound = 'food_not_found';
  static const confirmationRequired = 'confirmation_required';
  static const duplicate = 'duplicate_request';
  static const allergyConflict = 'allergy_conflict';
  static const mealRequired = 'meal_required';
}

Failure foodCaptureFailure(String code) {
  return switch (code) {
    FoodCaptureCodes.notConfigured ||
    FoodCaptureCodes.unavailable => NotImplementedFailure(code),
    FoodCaptureCodes.offline ||
    FoodCaptureCodes.timeout => NetworkFailure(code, code: code),
    FoodCaptureCodes.rateLimited => ServerFailure(
      code,
      code: code,
      statusCode: 429,
    ),
    FoodCaptureCodes.permissionDenied => const PermissionFailure(
      FoodCaptureCodes.permissionDenied,
    ),
    _ => UnexpectedFailure(code, code: code),
  };
}

AppException foodCaptureException(String code) {
  return switch (code) {
    FoodCaptureCodes.notConfigured ||
    FoodCaptureCodes.unavailable => ServiceUnavailableException(
      code,
      code: code,
    ),
    FoodCaptureCodes.permissionDenied => const PermissionException(
      FoodCaptureCodes.permissionDenied,
      code: FoodCaptureCodes.permissionDenied,
    ),
    FoodCaptureCodes.rateLimited ||
    FoodCaptureCodes.offline ||
    FoodCaptureCodes.timeout => NetworkException(code, code: code),
    _ => NetworkException(code, code: code),
  };
}

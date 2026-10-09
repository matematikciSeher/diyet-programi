import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/network/dio_api_client.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/services/media/photo_picker_service.dart';
import '../../../../shared/services/service_providers.dart';
import '../../../ai_coach/domain/services/assistant_limits.dart';
import '../../../meals/data/repositories/meal_log_repository_impl.dart';
import '../../data/repositories/food_repository_impl.dart';
import '../../domain/models/food_log_draft.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/services/capture_submission_guard.dart';
import '../../domain/services/food_capture_codes.dart';
import '../../domain/services/food_draft_builder.dart';
import '../../domain/services/food_image_policy.dart';
import '../../domain/services/food_vision_selector.dart';
import '../../domain/services/food_vision_service.dart';
import '../../domain/services/proxy_food_vision_service.dart';
import '../../domain/services/speech_input_service.dart';
import '../../domain/services/spoken_meal_parser.dart';
import '../../domain/usecases/log_estimated_foods.dart';
import 'food_providers.dart';

enum FoodCapturePhase { uploading, analyzing, matching, parsing, ready }

final foodPhotoPickerProvider = Provider<PhotoPickerService>((ref) {
  final config = ref.watch(appConfigProvider);
  return ImagePickerPhotoService(
    maxDimension: config.effectiveFoodVisionMaxImageDimension.toDouble(),
    jpegQuality: config.effectiveFoodVisionJpegQuality,
  );
});

final foodImagePolicyProvider = Provider<FoodImagePolicy>(
  (ref) => FoodImagePolicy.fromConfig(ref.watch(appConfigProvider)),
);

final foodVisionServiceProvider = Provider<FoodVisionService>((ref) {
  final config = ref.watch(appConfigProvider);
  return selectFoodVisionService(
    config: config,
    isRelease: kReleaseMode,
    fake: const MockFoodVisionService(),
    proxy: _proxyVision(ref, config),
  );
});

FoodVisionService _proxyVision(Ref ref, AppConfig config) {
  if (!config.isAiProxyConfigured) return const UnconfiguredFoodVisionService();
  final timeout = config.aiTimeoutSeconds < 5 || config.aiTimeoutSeconds > 60
      ? 20
      : config.aiTimeoutSeconds;
  return ProxyFoodVisionService(
    client: DioApiClient.create(
      baseUrl: config.aiProxyBaseUrl.trim(),
      timeout: Duration(seconds: timeout),
      tokenProvider: () => ref.read(authServiceProvider).getIdToken(),
    ),
    model: config.aiModel,
    limiter: AssistantRateLimiter(
      maxPerMinute: config.aiMaxRequestsPerMinute < 1
          ? 8
          : config.aiMaxRequestsPerMinute,
    ),
  );
}

final speechInputServiceProvider = Provider<SpeechInputService>(
  (ref) => SpeechRecognitionBridge(ref.watch(speechRecognitionServiceProvider)),
);

final spokenMealParserProvider = Provider<SpokenMealParser>(
  (ref) => const SpokenMealParser(),
);

final foodDraftBuilderProvider = Provider<FoodDraftBuilder>(
  (ref) => const FoodDraftBuilder(),
);

final captureSubmissionGuardProvider = Provider<CaptureSubmissionGuard>(
  (ref) => CaptureSubmissionGuard(),
);

final confirmCapturedFoodsProvider = Provider<ConfirmCapturedFoods>(
  (ref) => ConfirmCapturedFoods(
    meals: ref.watch(mealLogRepositoryProvider),
    foods: ref.watch(foodRepositoryProvider),
    calculator: ref.watch(foodCalculationServiceProvider),
    clock: ref.watch(clockProvider),
    guard: ref.watch(captureSubmissionGuardProvider),
  ),
);

final foodCaptureActionsProvider = Provider<FoodCaptureActions>(
  (ref) => FoodCaptureActions(
    vision: ref.watch(foodVisionServiceProvider),
    foods: ref.watch(foodRepositoryProvider),
    builder: ref.watch(foodDraftBuilderProvider),
    parser: ref.watch(spokenMealParserProvider),
    policy: ref.watch(foodImagePolicyProvider),
  ),
);

/// Fotoğrafı geçici işler, aday üretir, katalogla eşleştirir. Günlüğe yazmaz.
class FoodCaptureActions {
  const FoodCaptureActions({
    required FoodVisionService vision,
    required FoodRepository foods,
    required FoodDraftBuilder builder,
    required SpokenMealParser parser,
    required FoodImagePolicy policy,
  }) : _vision = vision,
       _foods = foods,
       _builder = builder,
       _parser = parser,
       _policy = policy;

  final FoodVisionService _vision;
  final FoodRepository _foods;
  final FoodDraftBuilder _builder;
  final SpokenMealParser _parser;
  final FoodImagePolicy _policy;

  Future<Result<List<FoodLogDraft>>> analyzePhoto(
    Uint8List bytes, {
    UserProfile? profile,
    String? locale,
    String? requestId,
    void Function(FoodCapturePhase phase)? onPhase,
  }) async {
    onPhase?.call(FoodCapturePhase.uploading);
    final problem = _policy.validate(bytes);
    if (problem != null) return Result.failure(foodCaptureFailure(problem));
    onPhase?.call(FoodCapturePhase.analyzing);
    try {
      final candidates = await _vision.analyze(
        bytes,
        locale: locale,
        requestId: requestId,
      );
      if (candidates.isEmpty) {
        return Result.failure(
          foodCaptureFailure(FoodCaptureCodes.emptyResponse),
        );
      }
      onPhase?.call(FoodCapturePhase.matching);
      final drafts = await _builder.fromVision(
        _foods,
        candidates,
        profile: profile,
      );
      onPhase?.call(FoodCapturePhase.ready);
      return Result.success(drafts);
    } catch (error) {
      return Result.failure(mapExceptionToFailure(error));
    }
  }

  Future<Result<List<FoodLogDraft>>> analyzeTranscript(
    String text, {
    UserProfile? profile,
    void Function(FoodCapturePhase phase)? onPhase,
  }) async {
    onPhase?.call(FoodCapturePhase.parsing);
    final mentions = _parser.parse(text);
    onPhase?.call(FoodCapturePhase.matching);
    final drafts = await _builder.fromSpeech(
      _foods,
      mentions,
      profile: profile,
    );
    onPhase?.call(FoodCapturePhase.ready);
    return Result.success(drafts);
  }
}

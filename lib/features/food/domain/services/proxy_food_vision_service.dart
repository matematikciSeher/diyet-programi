import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../ai_coach/domain/services/assistant_limits.dart';
import '../models/vision_food_candidate.dart';
import 'food_capture_codes.dart';
import 'food_vision_service.dart';
import 'vision_payload_parser.dart';

/// Güvenli AI gateway'e fotoğraf gönderir.
///
/// Sağlayıcı anahtarı burada yoktur. Fotoğraf Firebase Storage, Firestore
/// veya senkron kuyruğuna yazılmaz. Geçici istek gövdesi yanıttan sonra
/// tutulmaz. Backend adresi yoksa bu sınıf oluşturulmamalı;
/// [UnconfiguredFoodVisionService] `AI_SERVICE_NOT_CONFIGURED` döner.
class ProxyFoodVisionService implements FoodVisionService {
  ProxyFoodVisionService({
    required ApiClient client,
    this.model = '',
    this.maxResponseChars = 65536,
    AssistantRateLimiter? limiter,
    int maxRequestsPerMinute = 8,
  }) : _client = client,
       _limiter =
           limiter ?? AssistantRateLimiter(maxPerMinute: maxRequestsPerMinute);

  static const path = '/v1/food/vision';

  final ApiClient _client;
  final String model;
  final int maxResponseChars;
  final AssistantRateLimiter _limiter;
  String? _inFlight;

  @override
  Future<List<VisionFoodCandidate>> analyze(
    Uint8List imageBytes, {
    String? locale,
    String? requestId,
  }) async {
    if (requestId != null && requestId == _inFlight) {
      throw const NetworkException(
        FoodCaptureCodes.duplicate,
        code: FoodCaptureCodes.duplicate,
      );
    }
    if (!_limiter.tryAcquire()) {
      throw const NetworkException(
        FoodCaptureCodes.rateLimited,
        code: FoodCaptureCodes.rateLimited,
      );
    }
    _inFlight = requestId;
    try {
      return await _client.post<List<VisionFoodCandidate>>(
        path,
        body: {
          'imageBase64': base64Encode(imageBytes),
          'mimeType': 'image/jpeg',
          if (locale != null && locale.isNotEmpty) 'locale': locale,
          if (model.trim().isNotEmpty) 'model': model.trim(),
        },
        decoder: (data) => parseVisionPayload(
          data,
          maxChars: maxResponseChars,
        ),
      );
    } on AppException {
      rethrow;
    } finally {
      if (_inFlight == requestId) _inFlight = null;
    }
  }
}

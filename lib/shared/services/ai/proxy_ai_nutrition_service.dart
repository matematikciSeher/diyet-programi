import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import 'ai_nutrition_service.dart';

/// Güvenli backend proxy'ye giden HTTP adaptörü.
///
/// Sağlayıcı anahtarı burada yoktur. İstek, varsa kullanıcının kimlik
/// token'ı ile gider. Fotoğraf ve ses bu aşamada üretime alınmaz; mevcut
/// [AiNutritionService] noktaları korunur ve sahte yiyecek döndürmez.
class ProxyAiNutritionService implements AiNutritionService {
  const ProxyAiNutritionService({
    required ApiClient client,
    this.model = '',
    this.maxOutputTokens = 512,
  }) : _client = client;

  final ApiClient _client;
  final String model;
  final int maxOutputTokens;

  static const chatPath = '/v1/assistant';

  @override
  Stream<String> chat(List<AiChatMessage> messages) async* {
    final body = <String, Object?>{
      if (model.trim().isNotEmpty) 'model': model.trim(),
      'maxOutputTokens': maxOutputTokens,
      'messages': [
        for (final message in messages)
          {'role': message.role.name, 'content': message.content},
      ],
    };
    final payload = await _client.post<String>(
      chatPath,
      body: body,
      decoder: _readPayload,
    );
    yield payload;
  }

  @override
  Future<List<RecognizedFood>> analyzeMealPhoto(
    Uint8List imageBytes, {
    String? locale,
  }) {
    throw const ServiceUnavailableException(
      'unavailable',
      code: 'unavailable',
    );
  }

  @override
  Future<List<RecognizedFood>> parseMealDescription(
    String text, {
    String? locale,
  }) {
    throw const ServiceUnavailableException(
      'unavailable',
      code: 'unavailable',
    );
  }

  static String _readPayload(Object? data) {
    if (data is String && data.trim().isNotEmpty) return data;
    if (data is Map) {
      final content = data['content'];
      if (content is String && content.trim().isNotEmpty && data['text'] == null) {
        return content;
      }
      if (data['text'] is String || data['actions'] is List) {
        return jsonEncode(data);
      }
    }
    throw const NetworkException(
      'malformed_response',
      code: 'malformed_response',
    );
  }
}

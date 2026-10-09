import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../core/errors/app_exception.dart';
import '../../models/nutrition_facts.dart';

class AiChatMessage extends Equatable {
  const AiChatMessage({required this.role, required this.content});

  final AiChatRole role;
  final String content;

  @override
  List<Object?> get props => [role, content];
}

enum AiChatRole { user, assistant, system }

/// Fotoğraf/ses/metin analizinden çıkarılan tahmini yemek.
class RecognizedFood extends Equatable {
  const RecognizedFood({
    required this.name,
    required this.estimatedGrams,
    required this.nutrition,
    required this.confidence,
  });

  final String name;
  final double estimatedGrams;
  final NutritionFacts nutrition;

  /// 0..1
  final double confidence;

  @override
  List<Object?> get props => [name, estimatedGrams, nutrition, confidence];
}

/// AI destekli beslenme asistanı, fotoğraftan yemek analizi ve serbest
/// metinden (sesle ekleme sonrası) yemek çıkarımı.
///
/// GÜVENLİK: AI sağlayıcı anahtarı istemcide TUTULMAZ. Implementasyon,
/// kullanıcının Firebase ID token'ı ile doğrulanan bir backend proxy'ye
/// (`AppConfig.aiProxyBaseUrl`) istek atar.
abstract interface class AiNutritionService {
  Stream<String> chat(List<AiChatMessage> messages);

  Future<List<RecognizedFood>> analyzeMealPhoto(
    Uint8List imageBytes, {
    String? locale,
  });

  Future<List<RecognizedFood>> parseMealDescription(
    String text, {
    String? locale,
  });
}

class UnavailableAiNutritionService implements AiNutritionService {
  const UnavailableAiNutritionService();

  static const _error = ServiceUnavailableException('ai_not_configured');

  @override
  Stream<String> chat(List<AiChatMessage> messages) => Stream.error(_error);

  @override
  Future<List<RecognizedFood>> analyzeMealPhoto(
    Uint8List imageBytes, {
    String? locale,
  }) => throw _error;

  @override
  Future<List<RecognizedFood>> parseMealDescription(
    String text, {
    String? locale,
  }) => throw _error;
}

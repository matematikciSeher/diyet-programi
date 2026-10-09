import 'dart:typed_data';

import '../../../../core/errors/app_exception.dart';
import '../models/vision_food_candidate.dart';
import 'food_capture_codes.dart';

/// Fotoğraftan yiyecek adayı. Sonuç günlüğe yazılmaz.
///
/// Debug/test (`useFakeServices` ve release değil) sahte servisi kullanabilir.
/// Release sahte sonuç döndürmez. Besin değeri bu sözleşmede yoktur.
abstract interface class FoodVisionService {
  Future<List<VisionFoodCandidate>> analyze(
    Uint8List imageBytes, {
    String? locale,
    String? requestId,
  });
}

/// Yalnızca debug/test. Release seçicisi bu sınıfı döndürmez.
/// Dönen satırlar adaydır; kalori içermez ve onay olmadan kaydedilmez.
class MockFoodVisionService implements FoodVisionService {
  const MockFoodVisionService({
    this.delay = Duration.zero,
    this.candidates = samples,
    this.error,
  });

  final Duration delay;
  final List<VisionFoodCandidate> candidates;
  final AppException? error;

  static const samples = [
    VisionFoodCandidate(
      name: 'Haşlanmış yumurta',
      estimatedGrams: 100,
      confidence: 0.86,
      source: 'vision',
    ),
    VisionFoodCandidate(
      name: 'Beyaz peynir (feta)',
      estimatedGrams: 50,
      confidence: 0.74,
      source: 'vision',
    ),
  ];

  @override
  Future<List<VisionFoodCandidate>> analyze(
    Uint8List imageBytes, {
    String? locale,
    String? requestId,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return List<VisionFoodCandidate>.unmodifiable(candidates);
  }
}

class UnconfiguredFoodVisionService implements FoodVisionService {
  const UnconfiguredFoodVisionService();

  @override
  Future<List<VisionFoodCandidate>> analyze(
    Uint8List imageBytes, {
    String? locale,
    String? requestId,
  }) async {
    throw const ServiceUnavailableException(
      FoodCaptureCodes.notConfigured,
      code: FoodCaptureCodes.notConfigured,
    );
  }
}

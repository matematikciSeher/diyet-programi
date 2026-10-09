import 'package:equatable/equatable.dart';

/// Fotoğraf AI'sinin döndürdüğü aday.
///
/// `foodId`, isim, güven ve tahmini gram yalnızca adaydır. Kalori ve makro
/// bu modelde yoktur; AI yanıtındaki besin değerleri yok sayılır. Gerçek
/// değerler [Food] + [FoodCalculationService] ile, kullanıcı onayından sonra
/// hesaplanır.
class VisionFoodCandidate extends Equatable {
  const VisionFoodCandidate({
    required this.name,
    this.foodId,
    this.confidence = 0,
    this.estimatedGrams,
    this.source = 'vision',
  });

  final String name;

  /// Katalogda doğrulanmadan kullanılmaz.
  final String? foodId;

  /// 0..1. Eksikse 0.
  final double confidence;

  /// Modelin gram tahmini. Kesin porsiyon değildir; onay ekranında değişir.
  final double? estimatedGrams;
  final String source;

  @override
  List<Object?> get props => [name, foodId, confidence, estimatedGrams, source];
}

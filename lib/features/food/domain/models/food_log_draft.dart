import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';
import '../../../../shared/models/food.dart';
import '../services/food_match_service.dart';

/// Onay ekranındaki tek satır. Besin değeri taşımaz; kayıt anında
/// [FoodCalculationService] hesaplar.
class FoodLogDraft extends Equatable {
  const FoodLogDraft({
    required this.localId,
    required this.queryName,
    required this.matchStatus,
    required this.quantity,
    required this.unit,
    required this.source,
    this.food,
    this.options = const [],
    this.spokenUnitKey,
    this.baseAmount,
    this.assumption = false,
    this.needsAmount = false,
    this.confidence,
    this.allergyConflict = false,
    this.dislikeConflict = false,
    this.dietConflict = false,
    this.restrictionAcknowledged = false,
  });

  final String localId;
  final String queryName;
  final Food? food;
  final List<Food> options;
  final FoodMatchStatus matchStatus;
  final double quantity;
  final PortionUnit unit;

  /// `tea`, `spoon`, `plate` gibi mevcut [PortionUnit] etiketinden ayrılan söz.
  final String? spokenUnitKey;

  /// Temel ölçü (g veya ml). Belirsiz miktarda `null`.
  final double? baseAmount;
  final bool assumption;
  final bool needsAmount;
  final double? confidence;
  final FoodSource source;
  final bool allergyConflict;
  final bool dislikeConflict;
  final bool dietConflict;
  final bool restrictionAcknowledged;

  bool get hasRestriction =>
      allergyConflict || dislikeConflict || dietConflict;

  bool get canSave =>
      food != null &&
      matchStatus != FoodMatchStatus.notFound &&
      !needsAmount &&
      (baseAmount ?? 0) > 0 &&
      (!hasRestriction || restrictionAcknowledged);

  FoodLogDraft copyWith({
    String? queryName,
    Food? food,
    bool clearFood = false,
    List<Food>? options,
    FoodMatchStatus? matchStatus,
    double? quantity,
    PortionUnit? unit,
    String? spokenUnitKey,
    bool clearSpokenUnit = false,
    double? baseAmount,
    bool clearBaseAmount = false,
    bool? assumption,
    bool? needsAmount,
    double? confidence,
    bool? allergyConflict,
    bool? dislikeConflict,
    bool? dietConflict,
    bool? restrictionAcknowledged,
  }) {
    return FoodLogDraft(
      localId: localId,
      queryName: queryName ?? this.queryName,
      food: clearFood ? null : (food ?? this.food),
      options: options ?? this.options,
      matchStatus: matchStatus ?? this.matchStatus,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      source: source,
      spokenUnitKey: clearSpokenUnit ? null : (spokenUnitKey ?? this.spokenUnitKey),
      baseAmount: clearBaseAmount ? null : (baseAmount ?? this.baseAmount),
      assumption: assumption ?? this.assumption,
      needsAmount: needsAmount ?? this.needsAmount,
      confidence: confidence ?? this.confidence,
      allergyConflict: allergyConflict ?? this.allergyConflict,
      dislikeConflict: dislikeConflict ?? this.dislikeConflict,
      dietConflict: dietConflict ?? this.dietConflict,
      restrictionAcknowledged:
          restrictionAcknowledged ?? this.restrictionAcknowledged,
    );
  }

  @override
  List<Object?> get props => [
    localId,
    queryName,
    food,
    options,
    matchStatus,
    quantity,
    unit,
    spokenUnitKey,
    baseAmount,
    assumption,
    needsAmount,
    confidence,
    source,
    allergyConflict,
    dislikeConflict,
    dietConflict,
    restrictionAcknowledged,
  ];
}

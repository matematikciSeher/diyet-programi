import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/food.dart';

/// Kullanıcının seçtiği ölçü ve miktar (ör. 2 × "1 dilim = 25 g").
class PortionSelection extends Equatable {
  const PortionSelection({required this.portion, required this.quantity});

  factory PortionSelection.fromJson(Map<String, dynamic> json) =>
      PortionSelection(
        portion: FoodPortion.fromJson(JsonUtils.readMap(json['portion'])),
        quantity: JsonUtils.readDouble(json['quantity'], 1),
      );

  final FoodPortion portion;
  final double quantity;

  /// Toplam miktar, yiyeceğin temel ölçüsünde (g veya ml).
  double get baseAmount => portion.baseAmount * quantity;

  bool get isValid => quantity > 0 && portion.baseAmount > 0;

  PortionSelection copyWith({FoodPortion? portion, double? quantity}) =>
      PortionSelection(
        portion: portion ?? this.portion,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
    'portion': portion.toJson(),
    'quantity': quantity,
  };

  @override
  List<Object?> get props => [portion, quantity];
}

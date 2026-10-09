import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../../shared/models/food.dart';
import 'portion_selection.dart';

/// Son kullanılan yiyecek; tekrar eklemeyi hızlandırmak için en son seçilen
/// porsiyonla birlikte saklanır.
class RecentFood extends Equatable {
  const RecentFood({
    required this.food,
    required this.lastSelection,
    required this.lastUsedAt,
  });

  factory RecentFood.fromJson(Map<String, dynamic> json) => RecentFood(
    food: Food.fromJson(JsonUtils.readMap(json['food'])),
    lastSelection: PortionSelection.fromJson(
      JsonUtils.readMap(json['lastSelection']),
    ),
    lastUsedAt: JsonUtils.readDateOr(json['lastUsedAt'], DateTime(2000)),
  );

  final Food food;
  final PortionSelection lastSelection;
  final DateTime lastUsedAt;

  Map<String, dynamic> toJson() => {
    'food': food.toJson(),
    'lastSelection': lastSelection.toJson(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [food, lastSelection, lastUsedAt];
}

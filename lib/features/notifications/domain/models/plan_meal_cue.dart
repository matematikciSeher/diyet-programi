import 'package:equatable/equatable.dart';

import '../../../../shared/models/enums.dart';

/// Haftalık plandan bildirime taşınan öğün. Tarif adı ve saat dışında
/// besin değeri, alerji veya kişisel bilgi içermez.
class PlanMealCue extends Equatable {
  const PlanMealCue({
    required this.dayKey,
    required this.mealType,
    required this.title,
    this.timeMinutes,
  });

  final String dayKey;
  final MealType mealType;
  final String title;

  /// Gece yarısından itibaren dakika. Yoksa kullanıcının öğün saati kullanılır.
  final int? timeMinutes;

  @override
  List<Object?> get props => [dayKey, mealType, title, timeMinutes];
}

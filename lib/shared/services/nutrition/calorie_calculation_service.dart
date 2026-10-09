import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import 'nutrition_calculator.dart';
import 'profile_targets_service.dart';

/// BMR, TDEE ve günlük kalori/makro hedefini hesaplayan servis.
///
/// UI bu sınıfı kullanır; Mifflin-St Jeor formülü ve güvenlik kuralları
/// [NutritionCalculator] içindedir. Sonuç tıbbi tavsiye değildir.
class CalorieCalculationService {
  const CalorieCalculationService(this._calculator);

  final NutritionCalculator _calculator;

  NutritionInput? inputFor(UserProfile profile) =>
      ProfileTargetsService.inputFor(profile);

  double? bmr(UserProfile profile) {
    final input = inputFor(profile);
    return input == null ? null : _calculator.bmr(input);
  }

  double? tdee(UserProfile profile) {
    final input = inputFor(profile);
    return input == null ? null : _calculator.tdee(input);
  }

  /// Profil eksikse `null`. Aşırı düşük hedefler güvenlik tabanına çekilir.
  NutritionPlan? calculate(UserProfile profile, {DateTime? now}) {
    final input = inputFor(profile);
    if (input == null) return null;
    return _calculator.calculate(input, now: now);
  }
}

final calorieCalculationServiceProvider = Provider<CalorieCalculationService>(
  (ref) => CalorieCalculationService(ref.watch(nutritionCalculatorProvider)),
);

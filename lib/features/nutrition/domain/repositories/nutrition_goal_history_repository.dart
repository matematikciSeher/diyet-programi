import '../../../../core/errors/result.dart';
import '../models/nutrition_goal_history.dart';

/// Hedef: `FirestoreNutritionGoalHistoryRepository`.
abstract interface class NutritionGoalHistoryRepository {
  Stream<List<NutritionGoalHistory>> watch({int? limit});

  Future<Result<NutritionGoalHistory>> add(NutritionGoalHistory entry);
}

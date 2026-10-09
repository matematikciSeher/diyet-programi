import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/models/nutrition_goal_history.dart';
import '../../domain/repositories/nutrition_goal_history_repository.dart';

final class LocalNutritionGoalHistoryRepository extends UserScopedRepository
    implements NutritionGoalHistoryRepository {
  const LocalNutritionGoalHistoryRepository(super.db, super.uid);

  @override
  Stream<List<NutritionGoalHistory>> watch({int? limit}) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.nutritionGoalHistory(id),
          query: DocumentQuery(
            orderBy: 'createdAt',
            descending: true,
            limit: limit,
          ),
        )
        .map(
          (docs) => [
            for (final d in docs)
              NutritionGoalHistory.fromJson({...d.data, 'id': d.id}),
          ],
        );
  }

  @override
  Future<Result<NutritionGoalHistory>> add(NutritionGoalHistory entry) =>
      guard(() async {
        final collection = FirestorePaths.nutritionGoalHistory(requireUid());
        final saved = NutritionGoalHistory(
          id: entry.id.isEmpty ? db.generateId(collection) : entry.id,
          userId: requireUid(),
          createdAt: entry.createdAt,
          previousCalories: entry.previousCalories,
          newCalories: entry.newCalories,
          approved: entry.approved,
          reason: entry.reason,
          weightKg: entry.weightKg,
          previousProteinG: entry.previousProteinG,
          newProteinG: entry.newProteinG,
          previousCarbsG: entry.previousCarbsG,
          newCarbsG: entry.newCarbsG,
          previousFatG: entry.previousFatG,
          newFatG: entry.newFatG,
        );
        await db.setDocument('$collection/${saved.id}', saved.toJson());
        return saved;
      });
}

final nutritionGoalHistoryRepositoryProvider =
    Provider<NutritionGoalHistoryRepository>(
      (ref) => LocalNutritionGoalHistoryRepository(
        ref.watch(documentDatabaseProvider),
        ref.watch(currentUserIdProvider),
      ),
    );

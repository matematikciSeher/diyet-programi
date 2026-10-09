import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/nutrition_targets.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/models/daily_nutrition_score.dart';
import '../../domain/repositories/nutrition_score_repository.dart';
import '../../domain/services/daily_nutrition_score_service.dart';

final class LocalNutritionScoreRepository implements NutritionScoreRepository {
  const LocalNutritionScoreRepository(this._service);

  final DailyNutritionScoreService _service;

  @override
  DailyNutritionScore scoreFor(
    DailyLog log, {
    required NutritionTargets targets,
    required DateTime now,
  }) => _service.calculate(log: log, targets: targets, now: now);
}

final dailyNutritionScoreServiceProvider = Provider<DailyNutritionScoreService>(
  (ref) => const DailyNutritionScoreService(),
);

final nutritionScoreRepositoryProvider = Provider<NutritionScoreRepository>(
  (ref) => LocalNutritionScoreRepository(
    ref.watch(dailyNutritionScoreServiceProvider),
  ),
);

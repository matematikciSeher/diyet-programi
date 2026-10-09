import '../../../../shared/models/nutrition_targets.dart';
import '../models/daily_log.dart';
import '../models/daily_nutrition_score.dart';

/// Günlük beslenme skorunun kaynağı.
///
/// Şimdilik cihazda hesaplanır. İleride sunucu tarafı hesaplama (ör. Cloud
/// Functions) veya kişiselleştirilmiş bir puanlama bu arayüzün arkasına
/// bağlanabilir.
abstract interface class NutritionScoreRepository {
  DailyNutritionScore scoreFor(
    DailyLog log, {
    required NutritionTargets targets,
    required DateTime now,
  });
}

import 'package:equatable/equatable.dart';

import '../../../../core/utils/json_utils.dart';
import '../../../dashboard/domain/nutrition_score.dart';

/// Bir faktörün kullanıcıya gösterilen durumu (✓ / △ / ✗).
enum ScoreFactorStatus { met, partial, missed }

class ScoreFactorCheck extends Equatable {
  const ScoreFactorCheck({
    required this.factor,
    required this.progress,
    required this.status,
  });

  final ScoreFactor factor;

  /// 0–1 arası.
  final double progress;
  final ScoreFactorStatus status;

  @override
  List<Object?> get props => [factor, progress, status];
}

/// Bir günün beslenme skoru ve öne çıkan faktörleri.
/// Genel bir alışkanlık göstergesidir; tıbbi değerlendirme değildir.
class DailyNutritionScore extends Equatable {
  const DailyNutritionScore({required this.breakdown, required this.checks});

  factory DailyNutritionScore.fromJson(Map<String, dynamic> json) {
    final factors = JsonUtils.readMap(json['factors']);
    final breakdown = NutritionScore([
      for (final f in ScoreFactor.values)
        if (factors.containsKey(f.name))
          ScoreComponent(f, JsonUtils.readDouble(factors[f.name])),
    ]);
    return DailyNutritionScore(
      breakdown: breakdown,
      checks: [
        for (final check in JsonUtils.readMapList(json['checks']))
          if (JsonUtils.readEnumOrNull(ScoreFactor.values, check['factor'])
              case final factor?)
            ScoreFactorCheck(
              factor: factor,
              progress: JsonUtils.readDouble(check['progress']),
              status: JsonUtils.readEnum(
                ScoreFactorStatus.values,
                check['status'],
                ScoreFactorStatus.missed,
              ),
            ),
      ],
    );
  }

  /// Tüm faktörlerin puan dökümü (detay ekranı için).
  final NutritionScore breakdown;

  /// Özet kartında gösterilen faktörler, gösterim sırasıyla.
  final List<ScoreFactorCheck> checks;

  int get value => breakdown.value;
  ScoreBand get band => breakdown.band;

  Map<String, dynamic> toJson() => {
    'value': value,
    'factors': {
      for (final c in breakdown.components) c.factor.name: c.progress,
    },
    'checks': [
      for (final c in checks)
        {
          'factor': c.factor.name,
          'progress': c.progress,
          'status': c.status.name,
        },
    ],
  };

  @override
  List<Object?> get props => [breakdown, checks];
}

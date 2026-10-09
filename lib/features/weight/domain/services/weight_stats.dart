import 'package:equatable/equatable.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/enums.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../progress/domain/models/progress_report.dart';

/// Kilo grafiğinin kapsadığı dönem; `days == null` tüm kayıtlar.
enum WeightRange {
  week(7),
  month(30),
  quarter(90),
  all(null);

  const WeightRange(this.days);

  final int? days;
}

/// Kilo Takibi ekranının özeti. Başlangıç kilosu profilden (onboarding)
/// ya da ilk kayıttan, güncel kilo en yeni kayıttan gelir.
class WeightStats extends Equatable {
  const WeightStats({
    required this.progress,
    required this.series,
    required this.points,
    required this.entries,
    this.weeklyChangeKg,
  });

  static WeightStats? compute({
    required List<WeightEntry> entries,
    required WeightRange range,
    required DateTime now,
    UserProfile? profile,
  }) {
    final sorted = [...entries]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final series = [for (final e in sorted) WeightPoint(e.recordedAt, e.weightKg)];
    final baseline = profile?.effectiveStartWeight;
    if (baseline != null &&
        (series.isEmpty || profile!.createdAt.isBefore(series.first.date))) {
      series.insert(0, WeightPoint(profile!.createdAt, baseline));
    }
    if (series.isEmpty) return null;

    final start = series.first.kg;
    final target = profile?.targetWeight;
    final WeightDirection direction;
    if (target != null && target != start) {
      direction = target < start ? WeightDirection.lose : WeightDirection.gain;
    } else {
      direction = switch (profile?.goal) {
        GoalType.gainWeight || GoalType.buildMuscle => WeightDirection.gain,
        _ => WeightDirection.lose,
      };
    }

    final days = range.days;
    final from = days == null
        ? null
        : now.startOfDay.addDays(-(days - 1));
    final points = from == null
        ? series
        : [
            for (final p in series)
              if (!p.date.isBefore(from)) p,
          ];

    return WeightStats(
      progress: WeightProgress(
        startKg: start,
        currentKg: series.last.kg,
        targetKg: target,
        direction: direction,
      ),
      series: series,
      points: points,
      entries: sorted.reversed.toList(),
      weeklyChangeKg: _weeklyChange(series),
    );
  }

  /// Başlangıçtan bu yana haftalık ortalama değişim (kg/hafta). En az bir
  /// haftalık veri yoksa `null`.
  static double? _weeklyChange(List<WeightPoint> series) {
    if (series.length < 2) return null;
    final days =
        series.last.date.difference(series.first.date).inHours / Duration.hoursPerDay;
    if (days < 7) return null;
    return (series.last.kg - series.first.kg) / (days / 7);
  }

  final WeightProgress progress;

  /// Tüm noktalar, eskiden yeniye.
  final List<WeightPoint> series;

  /// Seçili dönemdeki noktalar, eskiden yeniye.
  final List<WeightPoint> points;

  /// Kullanıcının girdiği kayıtlar, en yeni önce.
  final List<WeightEntry> entries;
  final double? weeklyChangeKg;

  double get startKg => progress.startKg;
  double get currentKg => progress.currentKg;
  double? get targetKg => progress.targetKg;

  /// Güncel − başlangıç (kilo verildiyse negatif).
  double get totalChangeKg => currentKg - startKg;

  double get changePercent => startKg == 0 ? 0 : totalChangeKg / startKg * 100;

  WeightEntry? get latestEntry => entries.firstOrNull;

  /// Kaydın bir önceki kayda göre farkı.
  double? changeFromPrevious(WeightEntry entry) {
    final index = entries.indexOf(entry);
    if (index < 0 || index + 1 >= entries.length) return null;
    return entry.weightKg - entries[index + 1].weightKg;
  }

  @override
  List<Object?> get props => [progress, series, points, entries, weeklyChangeKg];
}

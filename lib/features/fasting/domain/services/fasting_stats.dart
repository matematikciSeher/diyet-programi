import 'package:equatable/equatable.dart';

import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/fasting_session.dart';

/// Bitmiş oturumların Bugün / Dün / Son 7 gün gruplaması ve özetleri.
class FastingHistory extends Equatable {
  const FastingHistory({
    required this.today,
    required this.yesterday,
    required this.earlier,
    required this.completedCount,
    required this.sessionCount,
    this.averageDuration,
  });

  /// Bitiş gününe göre gruplar; en yeni önce.
  final List<FastingSession> today;
  final List<FastingSession> yesterday;

  /// Son 7 günün bugün ve dün dışındaki oturumları.
  final List<FastingSession> earlier;

  /// Son 7 günde hedefe ulaşan oturum sayısı.
  final int completedCount;
  final int sessionCount;

  /// Son 7 günün bitmiş oturumlarının ortalama süresi.
  final Duration? averageDuration;

  bool get isEmpty => sessionCount == 0;

  @override
  List<Object?> get props => [
    today,
    yesterday,
    earlier,
    completedCount,
    sessionCount,
    averageDuration,
  ];
}

abstract final class FastingStats {
  static const days = 7;

  static FastingHistory history(List<FastingSession> sessions, DateTime now) {
    final today = now.startOfDay;
    final yesterday = today.addDays(-1);
    final from = today.addDays(-(days - 1));
    final ended = [
      for (final s in sessions)
        if (s.endedAt case final end? when !end.startOfDay.isBefore(from)) s,
    ]..sort((a, b) => b.endedAt!.compareTo(a.endedAt!));

    final durations = [for (final s in ended) s.elapsed(s.endedAt!)];
    final average = durations.isEmpty
        ? null
        : Duration(
            seconds:
                durations.fold(0, (sum, d) => sum + d.inSeconds) ~/
                durations.length,
          );

    return FastingHistory(
      today: [
        for (final s in ended)
          if (s.endedAt!.isSameDay(today)) s,
      ],
      yesterday: [
        for (final s in ended)
          if (s.endedAt!.isSameDay(yesterday)) s,
      ],
      earlier: [
        for (final s in ended)
          if (s.endedAt!.startOfDay.isBefore(yesterday)) s,
      ],
      completedCount: ended.where((s) => s.completed).length,
      sessionCount: ended.length,
      averageDuration: average,
    );
  }
}

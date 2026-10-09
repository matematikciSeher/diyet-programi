import 'package:equatable/equatable.dart';

import '../../../../shared/models/fasting_session.dart';
import '../models/fasting_schedule.dart';

/// Oruç ekranındaki dairesel zamanlayıcının anlık durumu.
class FastingTimerState extends Equatable {
  const FastingTimerState({
    required this.phase,
    required this.elapsed,
    required this.remaining,
    required this.total,
    this.session,
    this.phaseEndsAt,
  });

  final FastingPhase phase;

  /// Oruçta: oruç süresi. Yeme penceresinde: pencerenin geçen kısmı.
  final Duration elapsed;

  /// Hedefe/pencerenin bitişine kalan süre; en az sıfır.
  final Duration remaining;
  final Duration total;

  /// Devam eden oruç; yeme penceresindeyken `null`.
  final FastingSession? session;

  /// Duraklatılmış oruçta `null`.
  final DateTime? phaseEndsAt;

  bool get isFasting => phase == FastingPhase.fasting && session != null;
  bool get isPaused => session?.isPaused ?? false;
  bool get targetReached => isFasting && remaining == Duration.zero;

  double get progress {
    if (total == Duration.zero) return 0;
    return (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    phase,
    elapsed,
    remaining,
    total,
    session,
    phaseEndsAt,
  ];
}

abstract final class FastingTimer {
  /// Aktif oturum varsa oruç süresi gösterilir. Yoksa yeme penceresi:
  /// son oruç bittiyse oradan, değilse günlük düzenden hesaplanır.
  static FastingTimerState compute({
    required FastingSchedule schedule,
    required DateTime now,
    FastingSession? active,
    FastingSession? lastEnded,
  }) {
    if (active != null) {
      final target = active.targetDuration;
      final elapsed = active.elapsed(now);
      final remaining = _positive(target - elapsed);
      return FastingTimerState(
        phase: FastingPhase.fasting,
        elapsed: elapsed,
        remaining: remaining,
        total: target,
        session: active,
        phaseEndsAt: active.isPaused ? null : now.add(remaining),
      );
    }

    final eating = schedule.eatingDuration;
    final endedAt = lastEnded?.endedAt;
    if (endedAt != null &&
        !endedAt.isAfter(now) &&
        now.isBefore(endedAt.add(eating))) {
      final elapsed = now.difference(endedAt);
      return FastingTimerState(
        phase: FastingPhase.eating,
        elapsed: elapsed,
        remaining: eating - elapsed,
        total: eating,
        phaseEndsAt: endedAt.add(eating),
      );
    }

    final phase = schedule.phaseAt(now);
    final end = schedule.currentPhaseEnd(now);
    final total = phase == FastingPhase.eating
        ? eating
        : schedule.fastingDuration;
    final remaining = _positive(end.difference(now));
    return FastingTimerState(
      phase: phase,
      elapsed: _positive(total - remaining),
      remaining: remaining,
      total: total,
      phaseEndsAt: end,
    );
  }

  static Duration _positive(Duration d) => d.isNegative ? Duration.zero : d;
}

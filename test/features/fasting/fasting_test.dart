import 'package:diyet_programi/features/fasting/domain/models/fasting_schedule.dart';
import 'package:diyet_programi/features/fasting/domain/services/fasting_stats.dart';
import 'package:diyet_programi/features/fasting/domain/services/fasting_timer.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/fasting_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  const schedule = FastingSchedule(
    protocol: FastingPreference.sixteenEight,
    eatingStartMinutes: 12 * 60,
  );

  test('yeme penceresinde kalan süre pencere bitişine göredir', () {
    final now = DateTime(2026, 9, 28, 14, 30);
    final state = FastingTimer.compute(schedule: schedule, now: now);
    expect(state.phase, FastingPhase.eating);
    expect(state.elapsed, const Duration(hours: 2, minutes: 30));
    expect(state.remaining, const Duration(hours: 5, minutes: 30));
    expect(state.session, isNull);
  });

  test('aktif oruçta geçen ve kalan süre hedefe göre hesaplanır', () {
    final now = DateTime(2026, 9, 28, 22);
    final session = FastingSession(
      id: 'fast-1',
      startedAt: DateTime(2026, 9, 28, 20),
      targetDuration: const Duration(hours: 16),
      protocol: FastingPreference.sixteenEight,
    );
    final state = FastingTimer.compute(
      schedule: schedule,
      now: now,
      active: session,
    );
    expect(state.phase, FastingPhase.fasting);
    expect(state.isFasting, isTrue);
    expect(state.elapsed, const Duration(hours: 2));
    expect(state.remaining, const Duration(hours: 14));
  });

  test('geçmiş bugün / dün / tamamlanan oruçları ayırır', () {
    final now = DateTime(2026, 9, 28, 18);
    final today = FastingSession(
      id: 'today',
      startedAt: DateTime(2026, 9, 28),
      targetDuration: const Duration(hours: 16),
      endedAt: DateTime(2026, 9, 28, 16),
      protocol: FastingPreference.sixteenEight,
    );
    final yesterday = FastingSession(
      id: 'yesterday',
      startedAt: DateTime(2026, 9, 27),
      targetDuration: const Duration(hours: 16),
      endedAt: DateTime(2026, 9, 27, 12),
      protocol: FastingPreference.sixteenEight,
    );
    final history = FastingStats.history([today, yesterday], now);
    expect(history.today, [today]);
    expect(history.yesterday, [yesterday]);
    expect(history.sessionCount, 2);
    expect(history.completedCount, 1);
    expect(history.averageDuration, const Duration(hours: 14));
    expect(today.completed, isTrue);
    expect(yesterday.completed, isFalse);
  });

  test('protokol profildeki oruç tercihinden türetilir', () {
    final profile = testProfile(fasting: FastingPreference.fourteenTen);
    final fromProfile = FastingSchedule.fromProfile(profile)!;
    expect(fromProfile.protocol, FastingPreference.fourteenTen);
    expect(fromProfile.eatingStartMinutes, 12 * 60);
    expect(fromProfile.eatingEndMinutes, 22 * 60);
  });
}

import 'package:equatable/equatable.dart';

import '../../core/utils/json_utils.dart';
import 'enums.dart';

/// Aralıklı oruç oturumu. Konum: `users/{uid}/fasting_sessions/{id}`.
///
/// Duraklatılan süre oruç süresine sayılmaz: [elapsed], [pausedDuration] ve
/// devam eden duraklamayı düşer.
class FastingSession extends Equatable {
  const FastingSession({
    required this.id,
    required this.startedAt,
    required this.targetDuration,
    this.endedAt,
    this.protocol,
    this.pausedAt,
    this.pausedDuration = Duration.zero,
  });

  factory FastingSession.fromJson(Map<String, dynamic> json) => FastingSession(
    id: JsonUtils.readString(json['id']),
    startedAt: JsonUtils.readDateOr(json['startedAt'], DateTime.now()),
    targetDuration: Duration(
      minutes: JsonUtils.readInt(json['targetMinutes'], 16 * 60),
    ),
    endedAt: JsonUtils.readDate(json['endedAt']),
    protocol: JsonUtils.readEnumOrNull(
      FastingPreference.values,
      json['protocol'],
    ),
    pausedAt: JsonUtils.readDate(json['pausedAt']),
    pausedDuration: Duration(
      seconds: JsonUtils.readInt(json['pausedSeconds']),
    ),
  );

  final String id;
  final DateTime startedAt;
  final Duration targetDuration;
  final DateTime? endedAt;

  /// Oturum başlatılırken seçili protokol.
  final FastingPreference? protocol;

  /// Duraklatılmışsa duraklama anı.
  final DateTime? pausedAt;

  /// Önceki duraklamaların toplamı.
  final Duration pausedDuration;

  bool get isActive => endedAt == null;
  bool get isPaused => isActive && pausedAt != null;

  Duration elapsed(DateTime now) {
    final end = endedAt ?? pausedAt ?? now;
    final value = end.difference(startedAt) - pausedDuration;
    return value.isNegative ? Duration.zero : value;
  }

  /// Oruç hedef süreye ulaştı mı?
  bool reachedTarget(DateTime now) => elapsed(now) >= targetDuration;

  /// Tamamlanmış (bitirilmiş ve hedefe ulaşmış) oturum.
  bool get completed => endedAt != null && reachedTarget(endedAt!);

  FastingSession copyWith({
    String? id,
    DateTime? endedAt,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? pausedDuration,
  }) => FastingSession(
    id: id ?? this.id,
    startedAt: startedAt,
    targetDuration: targetDuration,
    endedAt: endedAt ?? this.endedAt,
    protocol: protocol,
    pausedAt: clearPausedAt ? null : (pausedAt ?? this.pausedAt),
    pausedDuration: pausedDuration ?? this.pausedDuration,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'targetMinutes': targetDuration.inMinutes,
    'endedAt': endedAt?.toIso8601String(),
    'protocol': protocol?.name,
    'pausedAt': pausedAt?.toIso8601String(),
    'pausedSeconds': pausedDuration.inSeconds,
  };

  @override
  List<Object?> get props => [
    id,
    startedAt,
    targetDuration,
    endedAt,
    protocol,
    pausedAt,
    pausedDuration,
  ];
}

import '../../../../core/config/app_config.dart';

/// Asistan isteğinin sınırları. Gizli anahtar içermez.
class AssistantLimits {
  const AssistantLimits({
    this.model = '',
    this.timeoutSeconds = 20,
    this.maxOutputTokens = 512,
    this.maxInputChars = 6000,
    this.maxMessageChars = 2000,
    this.maxRequestsPerMinute = 8,
    this.maxRetries = 0,
  });

  factory AssistantLimits.fromConfig(AppConfig config) {
    return AssistantLimits(
      model: config.aiModel.trim(),
      timeoutSeconds: _clamp(config.aiTimeoutSeconds, 5, 60, 20),
      maxOutputTokens: _clamp(config.aiMaxOutputTokens, 64, 1024, 512),
      maxInputChars: _clamp(config.aiMaxInputChars, 1000, 12000, 6000),
      maxMessageChars: _clamp(config.aiMaxMessageChars, 200, 4000, 2000),
      maxRequestsPerMinute: _clamp(config.aiMaxRequestsPerMinute, 1, 30, 8),
      maxRetries: _clamp(config.aiMaxRetries, 0, 2, 0),
    );
  }

  final String model;
  final int timeoutSeconds;
  final int maxOutputTokens;
  final int maxInputChars;
  final int maxMessageChars;
  final int maxRequestsPerMinute;
  final int maxRetries;

  Duration get timeout => Duration(seconds: timeoutSeconds);

  static int _clamp(int value, int min, int max, int fallback) {
    if (value < min || value > max) return fallback;
    return value;
  }
}

class AssistantRateLimiter {
  AssistantRateLimiter({
    required this.maxPerMinute,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int maxPerMinute;
  final DateTime Function() _clock;
  final List<DateTime> _stamps = [];

  bool tryAcquire() {
    final now = _clock();
    _stamps.removeWhere(
      (stamp) => now.difference(stamp) >= const Duration(minutes: 1),
    );
    if (_stamps.length >= maxPerMinute) return false;
    _stamps.add(now);
    return true;
  }
}

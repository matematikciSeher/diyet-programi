import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splash ekranının en az ne kadar görüneceği. Testlerde sıfırlanır.
final splashMinDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1200),
);

/// Uygulama açılışında tamamlanması beklenen işler. Router, bu provider
/// yüklenirken kullanıcıyı splash ekranında tutar.
final appStartupProvider = FutureProvider<void>((ref) async {
  final minDuration = ref.watch(splashMinDurationProvider);
  if (minDuration > Duration.zero) await Future<void>.delayed(minDuration);
});

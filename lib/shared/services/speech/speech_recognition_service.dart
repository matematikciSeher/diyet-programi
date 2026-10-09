/// Sesle yemek ekleme için konuşmadan metne.
/// Hedef: speech_to_text paketi (cihaz üzerinde).
abstract interface class SpeechRecognitionService {
  Future<bool> isAvailable();

  /// Kısmi ve nihai sonuçları yayınlar.
  Stream<String> listen({String? localeId, Duration? listenFor});

  Future<void> stop();
}

class UnavailableSpeechRecognitionService implements SpeechRecognitionService {
  const UnavailableSpeechRecognitionService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Stream<String> listen({String? localeId, Duration? listenFor}) =>
      const Stream.empty();

  @override
  Future<void> stop() async {}
}

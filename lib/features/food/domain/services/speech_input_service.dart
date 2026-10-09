import '../../../../shared/services/speech/speech_recognition_service.dart';

/// Konuşmadan metne. Çözümleme [SpokenMealParser] ile yerel yapılır;
/// besin değeri burada üretilmez.
abstract interface class SpeechInputService {
  Future<bool> isAvailable();

  Stream<String> listen({String? localeId, Duration? listenFor});

  Future<void> stop();
}

class MockSpeechInputService implements SpeechInputService {
  const MockSpeechInputService({this.available = false});

  final bool available;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<String> listen({String? localeId, Duration? listenFor}) =>
      const Stream.empty();

  @override
  Future<void> stop() async {}
}

/// Mevcut [SpeechRecognitionService] köprüsü.
class SpeechRecognitionBridge implements SpeechInputService {
  const SpeechRecognitionBridge(this._inner);

  final SpeechRecognitionService _inner;

  @override
  Future<bool> isAvailable() => _inner.isAvailable();

  @override
  Stream<String> listen({String? localeId, Duration? listenFor}) =>
      _inner.listen(localeId: localeId, listenFor: listenFor);

  @override
  Future<void> stop() => _inner.stop();
}

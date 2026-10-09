import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_service.dart';

/// Cihaz üzerindeki konuşmadan metne. Sağlayıcı anahtarı yoktur.
/// Metin daha sonra yerel ayrıştırıcıya gider; ses dosyası saklanmaz.
class SpeechToTextRecognitionService implements SpeechRecognitionService {
  SpeechToTextRecognitionService({this.maxDuration = const Duration(seconds: 30)});

  final Duration maxDuration;
  SpeechToText? _speech;

  SpeechToText get _engine => _speech ??= SpeechToText();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _engine.initialize();
    } on Object {
      return false;
    }
  }

  @override
  Stream<String> listen({String? localeId, Duration? listenFor}) {
    final controller = StreamController<String>();
    () async {
      try {
        final ready = await isAvailable();
        if (!ready) {
          controller.addError(StateError('speech_unavailable'));
          await controller.close();
          return;
        }
        await _engine.listen(
          onResult: (result) {
            if (controller.isClosed) return;
            controller.add(result.recognizedWords);
            if (result.finalResult) controller.close();
          },
          listenOptions: SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenFor: listenFor ?? maxDuration,
            localeId: localeId ?? 'tr_TR',
          ),
        );
      } on Object catch (error) {
        if (!controller.isClosed) {
          controller.addError(error);
          await controller.close();
        }
      }
    }();
    controller.onCancel = () {
      _speech?.stop();
    };
    return controller.stream;
  }

  @override
  Future<void> stop() => _speech?.stop() ?? Future<void>.value();
}

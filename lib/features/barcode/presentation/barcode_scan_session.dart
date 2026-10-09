import '../../../shared/services/barcode/barcode_digits.dart';

/// Kameradan gelen barkod tespitlerini tekilleştirir.
///
/// Aynı karede veya art arda gelen tekrarları yok sayar; bir barkod
/// kabul edildiğinde oturum meşgul kalır ta ki [release] çağrılana kadar.
class BarcodeScanSession {
  var _busy = false;
  String? _acceptedCode;

  bool get isBusy => _busy;

  String? get acceptedCode => _acceptedCode;

  static String normalize(String raw) => BarcodeDigits.normalize(raw);

  /// Tespit işlenmeliyse `true`. Meşgulken veya aynı kod tekrarında `false`.
  bool tryAccept(String raw) {
    final code = normalize(raw);
    if (code.isEmpty || _busy) return false;
    if (_acceptedCode == code) return false;
    _acceptedCode = code;
    _busy = true;
    return true;
  }

  /// Tarayıcıyı yeniden dinlemeye açar.
  ///
  /// [clearCode] true ise aynı barkod tekrar kabul edilebilir (ör. "Tekrar tara").
  void release({bool clearCode = false}) {
    _busy = false;
    if (clearCode) _acceptedCode = null;
  }
}

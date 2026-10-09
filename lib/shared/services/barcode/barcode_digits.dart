/// Barkod değerini rakam dizisi olarak korur.
///
/// Integer parse yapılmaz; leading zero kaybolmaz.
abstract final class BarcodeDigits {
  static final _nonDigits = RegExp(r'[^0-9]');
  static final _invalidRaw = RegExp(r'[^0-9\s-]');
  static const validLengths = {8, 12, 13, 14};

  /// Baş/sondaki boşluk ve ayırıcılar atılır; yalnızca rakamlar kalır.
  static String normalize(String raw) => raw.replaceAll(_nonDigits, '');

  static bool isDigitsOnly(String value) =>
      value.isNotEmpty && !_nonDigits.hasMatch(value);

  /// QR/URL ve telefon gibi geçersiz okumaları eler. EAN-8/12/13/14 kabul.
  static String? accept(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || _invalidRaw.hasMatch(trimmed)) return null;
    final code = normalize(trimmed);
    if (!validLengths.contains(code.length)) return null;
    return code;
  }
}

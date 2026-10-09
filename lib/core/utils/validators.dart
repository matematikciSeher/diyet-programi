/// Form alanları için saf doğrulama fonksiyonları.
/// Hata anahtarı döndürür; metin çevirisi presentation katmanında yapılır.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'required' : null;

  static String? email(String? value) {
    if (required(value) != null) return 'required';
    return _emailRegex.hasMatch(value!.trim()) ? null : 'invalid_email';
  }

  static String? password(String? value, {int minLength = 8}) {
    if (required(value) != null) return 'required';
    return value!.length >= minLength ? null : 'password_too_short';
  }

  static String? numberInRange(String? value, {num? min, num? max}) {
    if (required(value) != null) return 'required';
    final parsed = num.tryParse(value!.replaceAll(',', '.'));
    if (parsed == null) return 'invalid_number';
    if (min != null && parsed < min) return 'out_of_range';
    if (max != null && parsed > max) return 'out_of_range';
    return null;
  }
}

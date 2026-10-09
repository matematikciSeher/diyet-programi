/// Basit tercihler için senkron okunan, asenkron yazılan key-value depolama.
/// Hassas veriler (token vb.) için ileride ayrı bir `SecureStorage` eklenir.
abstract interface class KeyValueStorage {
  String? getString(String key);
  bool? getBool(String key);
  int? getInt(String key);

  Future<void> setString(String key, String value);
  Future<void> setBool(String key, {required bool value});
  Future<void> setInt(String key, int value);

  Future<void> remove(String key);
  Future<void> clear();
}

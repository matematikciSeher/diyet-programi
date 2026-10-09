typedef JsonDecoder<T> = T Function(Object? json);

/// HTTP istemci soyutlaması. Repository/servisler Dio'ya doğrudan bağımlı
/// olmaz. Hatalar `NetworkException` / `ServerException` olarak fırlatılır.
abstract interface class ApiClient {
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  });

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  });

  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  });

  Future<void> delete(String path, {Object? body});
}

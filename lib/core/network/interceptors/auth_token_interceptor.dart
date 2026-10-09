import 'package:dio/dio.dart';

/// Oturum açmış kullanıcının kimlik token'ını (Firebase ID token) döndürür.
typedef TokenProvider = Future<String?> Function();

/// Backend/proxy isteklerine `Authorization: Bearer <token>` ekler.
/// Böylece üçüncü parti API anahtarları yalnızca sunucuda kalır.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._tokenProvider);

  final TokenProvider _tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

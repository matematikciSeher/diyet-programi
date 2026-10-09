import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import 'api_client.dart';
import 'interceptors/auth_token_interceptor.dart';

class DioApiClient implements ApiClient {
  DioApiClient(this._dio);

  factory DioApiClient.create({
    required String baseUrl,
    TokenProvider? tokenProvider,
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    final limit = timeout ?? AppConstants.networkTimeout;
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: limit,
        receiveTimeout: limit,
        sendTimeout: limit,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: headers,
      ),
    );
    if (tokenProvider != null) {
      dio.interceptors.add(AuthTokenInterceptor(tokenProvider));
    }
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
    return DioApiClient(dio);
  }

  final Dio _dio;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) => _send(
    () => _dio.get<Object?>(path, queryParameters: queryParameters),
    decoder,
  );

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required JsonDecoder<T> decoder,
  }) => _send(
    () =>
        _dio.post<Object?>(path, data: body, queryParameters: queryParameters),
    decoder,
  );

  @override
  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonDecoder<T> decoder,
  }) => _send(() => _dio.put<Object?>(path, data: body), decoder);

  @override
  Future<void> delete(String path, {Object? body}) =>
      _send(() => _dio.delete<Object?>(path, data: body), (_) {});

  Future<T> _send<T>(
    Future<Response<Object?>> Function() request,
    JsonDecoder<T> decoder,
  ) async {
    try {
      final response = await request();
      return decoder(response.data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on AppException {
      rethrow;
    } on Object catch (e) {
      throw NetworkException(
        'malformed_response',
        code: 'malformed_response',
        cause: e,
      );
    }
  }

  AppException _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => NetworkException(
        'timeout',
        code: 'timeout',
        cause: e,
      ),
      DioExceptionType.connectionError => NetworkException(
        'no_connection',
        code: 'no_connection',
        cause: e,
      ),
      DioExceptionType.badResponse => _mapStatus(e),
      DioExceptionType.cancel => NetworkException('cancelled', cause: e),
      _ => NetworkException(e.message ?? 'unknown', cause: e),
    };
  }

  AppException _mapStatus(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      401 => AuthException('unauthorized', code: '401', cause: e),
      403 => const PermissionException('forbidden', code: '403'),
      404 => const NotFoundException('not_found', code: '404'),
      429 => NetworkException(
        'rate_limited',
        code: 'rate_limited',
        cause: e,
      ),
      500 || 502 || 503 => NetworkException(
        'unavailable',
        code: '$status',
        cause: e,
      ),
      _ => ServerException(
        e.response?.statusMessage ?? 'server_error',
        statusCode: status,
        cause: e,
      ),
    };
  }
}

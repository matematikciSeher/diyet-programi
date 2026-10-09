import 'package:diyet_programi/core/errors/app_exception.dart';
import 'package:diyet_programi/core/network/dio_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioApiClient _clientThatReplies(int status, [Object? data]) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException.badResponse(
            statusCode: status,
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: status,
              data: data,
            ),
          ),
        );
      },
    ),
  );
  return DioApiClient(dio);
}

void main() {
  test('429 NetworkException olur', () async {
    final client = _clientThatReplies(429);
    expect(
      () => client.get<Map<String, dynamic>>(
        '/x',
        decoder: (json) => const <String, dynamic>{},
      ),
      throwsA(
        isA<NetworkException>().having((e) => e.code, 'code', 'rate_limited'),
      ),
    );
  });

  test('503 NetworkException olur', () async {
    final client = _clientThatReplies(503);
    expect(
      () => client.get<Map<String, dynamic>>(
        '/x',
        decoder: (json) => const <String, dynamic>{},
      ),
      throwsA(isA<NetworkException>().having((e) => e.code, 'code', '503')),
    );
  });

  test('bozuk gövde malformed_response olur', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: '{'),
          );
        },
      ),
    );
    final client = DioApiClient(dio);
    expect(
      () => client.get<Map<String, dynamic>>(
        '/x',
        decoder: (json) {
          if (json is Map<String, dynamic>) return json;
          throw const FormatException('bad');
        },
      ),
      throwsA(
        isA<NetworkException>().having(
          (e) => e.code,
          'code',
          'malformed_response',
        ),
      ),
    );
  });
}

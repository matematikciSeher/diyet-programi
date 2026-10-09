import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/services/service_providers.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'dio_api_client.dart';

/// Ana backend için HTTP istemcisi.
/// Firebase Auth eklendiğinde `tokenProvider` ID token döndürecek şekilde
/// bağlanır.
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return DioApiClient.create(
    baseUrl: config.apiBaseUrl,
    tokenProvider: () => ref.read(authServiceProvider).getIdToken(),
  );
});

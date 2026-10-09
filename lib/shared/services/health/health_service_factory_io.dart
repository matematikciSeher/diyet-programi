import 'health_data_service.dart';
import 'health_service_selector.dart';
import 'platform_health_data_service.dart';

HealthDataService createHealthDataService({
  required bool useFakeServices,
  required bool isRelease,
  required bool platformSupported,
}) {
  final kind = resolveHealthServiceKind(
    useFakeServices: useFakeServices,
    isRelease: isRelease,
    platformSupported: platformSupported,
  );
  return switch (kind) {
    HealthServiceKind.platform => PlatformHealthDataService(),
    HealthServiceKind.unavailable => const UnavailableHealthDataService(),
  };
}

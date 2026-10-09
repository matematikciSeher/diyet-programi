import 'health_data_service.dart';

HealthDataService createHealthDataService({
  required bool useFakeServices,
  required bool isRelease,
  required bool platformSupported,
}) => const UnavailableHealthDataService();

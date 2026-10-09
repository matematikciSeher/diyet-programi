/// Release derlemesinde sahte sağlık servisi seçilmez.
enum HealthServiceKind { platform, unavailable }

HealthServiceKind resolveHealthServiceKind({
  required bool useFakeServices,
  required bool isRelease,
  required bool platformSupported,
}) {
  if (!isRelease && useFakeServices) return HealthServiceKind.unavailable;
  if (!platformSupported) return HealthServiceKind.unavailable;
  return HealthServiceKind.platform;
}

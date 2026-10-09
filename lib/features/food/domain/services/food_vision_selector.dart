import '../../../../core/config/app_config.dart';
import 'food_vision_service.dart';

/// Release ve yapılandırılmamış üretimde sahte fotoğraf sonucu kullanılmaz.
FoodVisionService selectFoodVisionService({
  required AppConfig config,
  required bool isRelease,
  required FoodVisionService proxy,
  required FoodVisionService fake,
}) {
  final allowFake = !isRelease && config.useFakeServices;
  if (allowFake) return fake;
  if (!config.isAiProxyConfigured) return const UnconfiguredFoodVisionService();
  return proxy;
}

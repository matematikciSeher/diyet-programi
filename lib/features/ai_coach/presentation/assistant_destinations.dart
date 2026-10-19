import '../../../core/routing/app_routes.dart';
import '../domain/models/assistant_reply.dart';

/// Asistan eylemlerinin gidebileceği gerçek rotalar.
///
/// Listede olmayan bir yol düğme olarak gösterilmez.
abstract final class AssistantDestinations {
  static const paths = <AssistantAction, String>{
    AssistantAction.openPlan: AppRoutes.nutritionPlan,
    AssistantAction.openDiary: AppRoutes.diary,
    AssistantAction.openWeight: AppRoutes.weight,
    AssistantAction.openFasting: AppRoutes.fasting,
    AssistantAction.openRecipes: AppRoutes.recipes,
    AssistantAction.openWater: AppRoutes.water,
    AssistantAction.openShopping: AppRoutes.shoppingList,
  };

  static const realPaths = {
    AppRoutes.nutritionPlan,
    AppRoutes.diary,
    AppRoutes.weight,
    AppRoutes.fasting,
    AppRoutes.recipes,
    AppRoutes.water,
    AppRoutes.shoppingList,
  };

  static String? routeOf(AssistantAction action) => knownRoute(paths[action]);

  static String? knownRoute(String? path) {
    if (path == null || !realPaths.contains(path)) return null;
    return path;
  }

  static List<AssistantAction> visible(Iterable<AssistantAction> actions) => [
    for (final action in actions)
      if (routeOf(action) != null) action,
  ];
}

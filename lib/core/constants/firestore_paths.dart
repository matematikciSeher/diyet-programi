/// Doküman veritabanı (Firestore) yol şeması.
///
/// Kullanıcı verileri `users/{uid}` altında alt koleksiyonlarda tutulur;
/// güvenlik kuralları bu yapıya göre yazılır.
abstract final class FirestorePaths {
  static const users = 'users';

  static String user(String uid) => '$users/$uid';

  static String weightEntries(String uid) => '${user(uid)}/weight_entries';
  static String measurements(String uid) => '${user(uid)}/measurements';
  static String progressPhotos(String uid) => '${user(uid)}/progress_photos';
  static String waterLogs(String uid) => '${user(uid)}/water_logs';
  static String mealEntries(String uid) => '${user(uid)}/meal_entries';
  static String mealPlans(String uid) => '${user(uid)}/meal_plans';
  static String shoppingLists(String uid) => '${user(uid)}/shopping_lists';
  static String nutritionGoalHistory(String uid) =>
      '${user(uid)}/nutrition_goal_history';
  static String fastingSessions(String uid) => '${user(uid)}/fasting_sessions';
  static String customFoods(String uid) => '${user(uid)}/custom_foods';
  static String favoriteFoods(String uid) => '${user(uid)}/favorite_foods';
  static String recentFoods(String uid) => '${user(uid)}/recent_foods';
  static String userRecipes(String uid) => '${user(uid)}/recipes';
  static String favoriteRecipes(String uid) => '${user(uid)}/favorite_recipes';
  static String recentRecipes(String uid) => '${user(uid)}/recent_recipes';
  static String dailyLogs(String uid) => '${user(uid)}/daily_logs';
  static String notificationSettings(String uid) =>
      '${user(uid)}/notification_settings';

  /// Sohbet geçmişi yalnızca cihazda tutulur. [userCollectionPaths] içinde
  /// yoktur; Firebase'e yazılmaz.
  static const assistantChatLocal = 'assistant_chat_local';

  /// Kullanıcı alt koleksiyonları (senkron/hydrate için).
  ///
  /// [assistantChatLocal] bilerek yoktur: sohbet geçmişi Firebase'e gitmez.
  static List<String> userCollectionPaths(String uid) => [
    weightEntries(uid),
    measurements(uid),
    progressPhotos(uid),
    waterLogs(uid),
    mealEntries(uid),
    mealPlans(uid),
    shoppingLists(uid),
    nutritionGoalHistory(uid),
    fastingSessions(uid),
    customFoods(uid),
    favoriteFoods(uid),
    recentFoods(uid),
    userRecipes(uid),
    favoriteRecipes(uid),
    recentRecipes(uid),
    dailyLogs(uid),
    notificationSettings(uid),
  ];

  /// [documentPath], [uid] profil belgesi ya da onun altındaki bir belge mi.
  ///
  /// `users/abc` ile `users/abc-2` karışmaz; eşleşme tam kök ya da `kök/` ile olur.
  static bool belongsToUser(String documentPath, String uid) {
    if (uid.isEmpty) return false;
    final root = user(uid);
    return documentPath == root || documentPath.startsWith('$root/');
  }

  static const notificationSettingsDocId = 'current';

  // Uygulama geneli (salt okunur) koleksiyonlar
  static const recipes = 'recipes';
  static const foods = 'foods';
}

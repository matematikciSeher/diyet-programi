import '../utils/extensions/date_extensions.dart';

/// Tüm rota yolları tek yerde tutulur; string'ler koda dağılmaz.
abstract final class AppRoutes {
  // Başlangıç akışı
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';

  // Ana sekmeler (StatefulShellRoute)
  static const dashboard = '/';
  static const diary = '/diary';
  static const plans = '/plans';
  static const progress = '/progress';
  static const profile = '/profile';

  // Sekmelerin üzerinde tam ekran açılan sayfalar
  static const nutritionPlan = '/nutrition-plan';
  static const foodSearch = '/food/search';
  static const foodDetail = '/food/item/:id';
  static const customFood = '/food/custom/new';
  static const recipeBuilder = '/food/recipe/new';
  static const barcodeScanner = '/food/barcode';
  static const photoLog = '/food/photo';
  static const voiceLog = '/food/voice';
  static const recipes = '/recipes';
  static const recipeCreate = '/recipes/new';
  static const recipeDetail = '/recipes/item/:id';
  static const shoppingList = '/shopping-list';
  static const water = '/water';
  static const weight = '/weight-tracking';
  static const measurements = '/body-measurements';
  static const fasting = '/intermittent-fasting';
  static const activity = '/activity';
  static const notifications = '/notifications';
  static const aiCoach = '/nutrition-assistant';
  static const personalInfo = '/personal-info';
  static const paywall = '/premium';
  static const settings = '/settings';

  static String recipeDetailPath(String id) =>
      '/recipes/item/${Uri.encodeComponent(id)}';

  /// Yemek arama/ekleme ekranları hangi öğüne ekleneceğini bu sorgu
  /// parametresiyle alır (ör. `/food/search?meal=lunch`).
  static const mealQueryParam = 'meal';

  /// Öğün baştan belli ise seçici gizlenir (`locked=1`).
  static const mealLockedQueryParam = 'locked';

  /// Günlük'te su kartına veya belirli bir öğüne odaklanmak için.
  static const sectionQueryParam = 'section';
  static const waterSection = 'water';

  /// Günlük'te bugünden farklı bir gün seçiliyken yemeğin ekleneceği gün
  /// (`yyyy-MM-dd`). Verilmezse bugüne eklenir.
  static const dateQueryParam = 'date';

  static String withMeal(
    String route,
    Enum? meal, {
    DateTime? date,
    bool lockMeal = false,
  }) => _withQuery(route, {
    if (meal != null) mealQueryParam: meal.name,
    if (lockMeal) mealLockedQueryParam: '1',
    if (date != null) dateQueryParam: date.dayKey,
  });

  static String diaryFocus({Enum? meal, String? section}) => _withQuery(diary, {
    mealQueryParam: ?meal?.name,
    sectionQueryParam: ?section,
  });

  static String foodDetailPath(
    String id, {
    Enum? meal,
    DateTime? date,
    bool lockMeal = false,
  }) => withMeal(
    '/food/item/${Uri.encodeComponent(id)}',
    meal,
    date: date,
    lockMeal: lockMeal,
  );

  /// Barkodla bulunamayan ürünü oluştururken barkod ön-doldurulur.
  static const barcodeQueryParam = 'barcode';

  static String customFoodPath({Enum? meal, String? barcode, DateTime? date}) =>
      _withQuery(customFood, {
        if (meal != null) mealQueryParam: meal.name,
        barcodeQueryParam: ?barcode,
        if (date != null) dateQueryParam: date.dayKey,
      });

  static String _withQuery(String path, Map<String, String> query) =>
      query.isEmpty ? path : Uri(path: path, queryParameters: query).toString();

  /// Paywall'u hangi premium özelliğin açtığı (analitik ve başlık için).
  static const featureQueryParam = 'feature';

  static String paywallPath({Enum? feature}) => feature == null
      ? paywall
      : Uri(
          path: paywall,
          queryParameters: {featureQueryParam: feature.name},
        ).toString();

  /// Oturum/onboarding gerektirmeyen rotalar.
  static const publicRoutes = {splash, onboarding, signIn};
}

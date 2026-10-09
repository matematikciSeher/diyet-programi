/// Yerel (key-value) depolama anahtarları.
abstract final class StorageKeys {
  static const themeMode = 'settings.theme_mode';
  static const localeCode = 'settings.locale';
  static const onboardingCompleted = 'onboarding.completed';
  static const onboardingDraft = 'onboarding.draft';
  static const userProfile = 'profile.current';

  /// Doküman veritabanının cihazdaki çevrimdışı kopyası.
  static const documentCache = 'db.cache.v1';

  /// Open Food Facts ürün önbelleği (Firebase'e senkron edilmez).
  static const foodLookupCache = 'food.lookup.cache.v1';

  /// Firebase'e henüz gönderilememiş yerel değişiklik kuyruğu.
  static const syncQueue = 'sync.queue.v1';

  /// Bulut verisi silinmiş hesaplar. Senkron kuyruğu bu UID'lere yeniden yazmaz.
  static const deletedAccountUids = 'account.deleted_uids';

  /// Bildirim tercihleri cihaza ve kullanıcıya özeldir.
  static String notificationSettings(String uid) => 'notifications.$uid';

  /// Cihazda uygulanmış hatırlatma planının parmak izi. Firebase'e gitmez;
  /// aynı plan yeniden kurulmasın diye yerelde tutulur.
  static String notificationSchedule(String uid) =>
      'notifications.schedule.$uid';

  /// Kullanıcının reddettiği kalori önerisi (kcal + kilo).
  static String dismissedCalorieTarget(String uid) =>
      'nutrition.dismissed_target.$uid';

  /// Health Connect / Apple Health aktivite önbelleği. Yalnızca cihazda tutulur;
  /// Firebase senkron kuyruğuna yazılmaz.
  static const healthActivityCache = 'health.activity.cache.v1';

  /// Kullanıcı sağlık verilerini bağlamayı seçti mi. İzin diyaloğu açmaz.
  static const healthLinked = 'health.linked';

  /// Başarılı sağlık okumasının uygulandığı yenileme nesli.
  static const healthSyncApplied = 'health.sync.applied';

  /// Yalnızca geliştirmedeki sahte mağaza; kullanıcı kimliği ile sonlanır.
  static String fakeSubscription(String appUserId) =>
      'subscription.fake.$appUserId';
}

import 'dart:async';

/// Uzak bildirimler. Hedef: `FirebaseMessagingService` (FCM).
/// Yerel hatırlatıcılar (su, öğün, oruç) ayrı bir `LocalNotificationService`
/// ile yönetilir.
abstract interface class PushNotificationService {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;

  /// Bildirime tıklanınca açılacak deep link (ör. `/water`).
  Stream<String> get onNotificationOpened;

  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

/// Planlanmış yerel hatırlatıcılar.
/// Hedef: flutter_local_notifications tabanlı implementasyon. Uygulama bu
/// arayüzü doğrudan değil `NotificationService` üzerinden kullanır.
abstract interface class LocalNotificationService {
  Future<void> initialize();

  /// Kullanıcıdan bildirim izni ister; izin verildiyse `true`.
  Future<bool> requestPermission();

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  });

  /// [weekday]: [DateTime.monday]..[DateTime.sunday].
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  });

  /// Tek seferlik bildirim (ör. aktif orucun bitişi).
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();

  /// İşletim sisteminde bekleyen bildirim kimlikleri.
  Future<Set<int>> pendingIds();

  /// Bildirim izni kapalıysa sistem ayarlarını açar.
  Future<void> openSystemSettings();

  /// Bildirime tıklanınca payload (rota) yayınlanır.
  Stream<String> get onNotificationTapped;
}

enum LocalNotificationRepeat { daily, weekly, once }

/// Planlanmış tek bir yerel bildirim.
class ScheduledLocalNotification {
  const ScheduledLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.repeat,
    this.hour,
    this.minute,
    this.weekday,
    this.at,
    this.payload,
  });

  final int id;
  final String title;
  final String body;
  final LocalNotificationRepeat repeat;
  final int? hour;
  final int? minute;
  final int? weekday;
  final DateTime? at;
  final String? payload;
}

/// Platform bildirimi göstermeden planı bellekte tutan implementasyon.
/// Geliştirme ve testte hangi bildirimlerin planlandığı buradan okunur;
/// gerçek eklenti bağlandığında `localNotificationServiceProvider`
/// override edilir.
class InMemoryLocalNotificationService implements LocalNotificationService {
  InMemoryLocalNotificationService({this.permissionGranted = true});

  bool permissionGranted;
  final Map<int, ScheduledLocalNotification> _scheduled = {};
  final _taps = StreamController<String>.broadcast();

  List<ScheduledLocalNotification> get scheduled =>
      _scheduled.values.toList(growable: false);

  @override
  Stream<String> get onNotificationTapped => _taps.stream;

  void simulateTap(String payload) => _taps.add(payload);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    _scheduled[id] = ScheduledLocalNotification(
      id: id,
      title: title,
      body: body,
      repeat: LocalNotificationRepeat.daily,
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    _scheduled[id] = ScheduledLocalNotification(
      id: id,
      title: title,
      body: body,
      repeat: LocalNotificationRepeat.weekly,
      weekday: weekday,
      hour: hour,
      minute: minute,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    _scheduled[id] = ScheduledLocalNotification(
      id: id,
      title: title,
      body: body,
      repeat: LocalNotificationRepeat.once,
      at: at,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) async => _scheduled.remove(id);

  @override
  Future<void> cancelAll() async => _scheduled.clear();

  @override
  Future<Set<int>> pendingIds() async => _scheduled.keys.toSet();

  var openedSystemSettings = false;

  @override
  Future<void> openSystemSettings() async {
    openedSystemSettings = true;
  }
}

class NoopPushNotificationService implements PushNotificationService {
  const NoopPushNotificationService();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<String> get onNotificationOpened => const Stream.empty();

  @override
  Future<void> subscribeToTopic(String topic) async {}

  @override
  Future<void> unsubscribeFromTopic(String topic) async {}
}

class NoopLocalNotificationService implements LocalNotificationService {
  const NoopLocalNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<Set<int>> pendingIds() async => const {};

  @override
  Future<void> openSystemSettings() async {}

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();
}

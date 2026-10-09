import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'push_notification_service.dart';
import '../../../features/notifications/domain/models/notification_settings.dart';

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse response) {
  // Arka plan isolate: asıl yönlendirme uygulama açılınca
  // [getNotificationAppLaunchDetails] ile yapılır.
}

/// flutter_local_notifications tabanlı gerçek yerel bildirimler.
/// İzin uygulama açılışında değil, kullanıcı hatırlatıcıları açınca istenir.
class FlutterLocalNotificationService implements LocalNotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  var _initialized = false;

  @override
  Stream<String> get onNotificationTapped => _taps.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _initTimeZone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: localNotificationTapBackground,
    );
    await _createChannels();
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true &&
        payload != null &&
        payload.isNotEmpty) {
      _taps.add(payload);
    }
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted =
            await android?.requestNotificationsPermission() ?? true;
        if (granted) {
          await android?.requestExactAlarmsPermission();
        }
        return granted;
      }
      if (Platform.isIOS || Platform.isMacOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        return await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> openSystemSettings() async {
    try {
      await openAppSettings();
    } on Object {
      // Ayarlar açılamazsa uygulama akışı sürer.
    }
  }

  @override
  Future<Set<int>> pendingIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((request) => request.id).toSet();
    } on Object {
      return const {};
    }
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) => _zoned(
    id: id,
    title: title,
    body: body,
    payload: payload,
    when: _next(hour, minute),
    match: DateTimeComponents.time,
    group: _groupOf(payload),
  );

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String? payload,
  }) => _zoned(
    id: id,
    title: title,
    body: body,
    payload: payload,
    when: _next(hour, minute, weekday: weekday),
    match: DateTimeComponents.dayOfWeekAndTime,
    group: _groupOf(payload),
  );

  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    await _zoned(
      id: id,
      title: title,
      body: body,
      payload: payload,
      when: tz.TZDateTime.from(at, tz.local),
      match: null,
      group: _groupOf(payload),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  void dispose() => _taps.close();

  Future<void> _zoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required DateTimeComponents? match,
    required ReminderGroup group,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(group),
        _channelName(group),
        channelDescription: _channelName(group),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: group.name),
    );
    try {
      await _schedule(
        id: id,
        title: title,
        body: body,
        when: when,
        details: details,
        match: match,
        payload: payload,
        mode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Object {
      await _schedule(
        id: id,
        title: title,
        body: body,
        when: when,
        details: details,
        match: match,
        payload: payload,
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    required DateTimeComponents? match,
    required AndroidScheduleMode mode,
    String? payload,
  }) => _plugin.zonedSchedule(
    id,
    title,
    body,
    when,
    details,
    androidScheduleMode: mode,
    matchDateTimeComponents: match,
    payload: payload,
  );

  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) _taps.add(payload);
  }

  static Future<void> _initTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } on Object {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }
  }

  Future<void> _createChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final group in ReminderGroup.values) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          _channelId(group),
          _channelName(group),
          description: _channelName(group),
          importance: Importance.high,
        ),
      );
    }
  }

  static tz.TZDateTime _next(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (weekday != null) {
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static String _channelId(ReminderGroup group) => 'reminders_${group.name}';

  static String _channelName(ReminderGroup group) => switch (group) {
    ReminderGroup.meal => 'Öğün',
    ReminderGroup.water => 'Su',
    ReminderGroup.fasting => 'Oruç',
    ReminderGroup.goal => 'Kilo',
    ReminderGroup.motivation => 'Motivasyon',
    ReminderGroup.plan => 'Plan',
  };

  static ReminderGroup _groupOf(String? payload) {
    final path = payload ?? '';
    if (path.contains('/plans')) return ReminderGroup.plan;
    if (path.contains('water') || path.contains('section=water')) {
      return ReminderGroup.water;
    }
    if (path.contains('fasting') || path.contains('intermittent')) {
      return ReminderGroup.fasting;
    }
    if (path.contains('weight')) return ReminderGroup.goal;
    if (path.contains('diary') || path.contains('meal=')) {
      return ReminderGroup.meal;
    }
    return ReminderGroup.motivation;
  }
}

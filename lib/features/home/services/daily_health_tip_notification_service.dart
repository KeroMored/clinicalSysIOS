import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/daily_health_tips.dart';

class DailyHealthTipNotificationService {
  static const String channelKey = 'daily_health_tips';
  static const int _baseNotificationId = 67000;
  static const String _lastScheduleDateKey =
      'daily_health_tip_notifications.last_schedule_date';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsReady = false;
  static bool _timeZonesReady = false;

  static Future<void> initialize() async {
    await _ensureLocalNotificationsReady();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static void _ensureTimeZonesReady() {
    if (_timeZonesReady) return;
    tz.initializeTimeZones();
    _timeZonesReady = true;
  }

  static Future<void> _ensureLocalNotificationsReady() async {
    if (_localNotificationsReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      channelKey,
      'النصائح اليومية',
      description: 'إشعار يومي بنصيحة صحية',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _localNotificationsReady = true;
  }

  static NotificationDetails _buildNotificationDetails({
    required String title,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelKey,
        'النصائح اليومية',
        channelDescription: 'إشعار يومي بنصيحة صحية',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<void> scheduleDailyTipsAtMidnight({int daysAhead = 7}) async {
    await _ensureLocalNotificationsReady();
    _ensureTimeZonesReady();

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();
    final lastScheduleDate = prefs.getString(_lastScheduleDateKey);

    if (lastScheduleDate == todayKey) {
      return;
    }

    final safeDaysAhead = daysAhead.clamp(1, 14).toInt();

    for (int i = 0; i < safeDaysAhead; i++) {
      await _localNotifications.cancel(_baseNotificationId + i);
    }

    for (int offset = 0; offset < safeDaysAhead; offset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      final tip = DailyHealthTips.getTipForDate(date);
      final dayNumber = DailyHealthTips.dayOfYear(date);
      final title = 'معلومة على الماشي';
      final body = ' $tip';

      await _localNotifications.zonedSchedule(
        _baseNotificationId + offset,
        title,
        body,
        tz.TZDateTime.from(
          DateTime(date.year, date.month, date.day, 0, 0, 0),
          tz.local,
        ),
        _buildNotificationDetails(title: title, body: body),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'daily_health_tip',
          'dayOfYear': '$dayNumber',
        }),
      );
    }

    await prefs.setString(_lastScheduleDateKey, todayKey);
  }

  static Future<void> scheduleDailyTipsAtTenPm() async {
    await scheduleDailyTipsAtMidnight();
  }

  static Future<void> sendNowForTesting() async {
    final now = DateTime.now();
    final tip = DailyHealthTips.getTipForDate(now);

    await _localNotifications.show(
      67999,
      'معلومة على الماشي',
      ' $tip',
      _buildNotificationDetails(
        title: 'معلومة على الماشي',
        body: ' $tip',
      ),
    );
  }
}

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/daily_health_tips.dart';

class DailyHealthTipNotificationService {
  static const String channelKey = 'daily_health_tips';
  static const int _baseNotificationId = 67000;
  static const String _lastScheduleDateKey =
      'daily_health_tip_notifications.last_schedule_date';

  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: channelKey,
        channelName: 'النصائح اليومية',
        channelDescription: 'إشعار يومي بنصيحة صحية',
        defaultColor: const Color(0xFF00BCD4),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      ),
    ]);

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleDailyTipsAtMidnight({int daysAhead = 7}) async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();
    final lastScheduleDate = prefs.getString(_lastScheduleDateKey);

    if (lastScheduleDate == todayKey) {
      return;
    }

    final safeDaysAhead = daysAhead.clamp(1, 14).toInt();

    // Cancel only the small rolling window we schedule.
    for (int i = 0; i < safeDaysAhead; i++) {
      await AwesomeNotifications().cancel(_baseNotificationId + i);
    }

    for (int offset = 0; offset < safeDaysAhead; offset++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: offset));
      final tip = DailyHealthTips.getTipForDate(date);
      final dayNumber = DailyHealthTips.dayOfYear(date);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _baseNotificationId + offset,
          channelKey: channelKey,
          title: 'معلومة على الماشي',
          body: ' $tip',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Reminder,
          wakeUpScreen: false,
          payload: {'type': 'daily_health_tip', 'dayOfYear': '$dayNumber'},
        ),
        schedule: NotificationCalendar.fromDate(
          date: DateTime(date.year, date.month, date.day, 0, 0, 0),
          repeats: false,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }

    await prefs.setString(_lastScheduleDateKey, todayKey);
  }

  static Future<void> scheduleDailyTipsAtTenPm() async {
    // Kept for backward compatibility with older callers.
    await scheduleDailyTipsAtMidnight();
  }

  static Future<void> sendNowForTesting() async {
    final now = DateTime.now();
    final tip = DailyHealthTips.getTipForDate(now);

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 67999,
        channelKey: channelKey,
        title: 'معلومة على الماشي',
        body: ' $tip',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Reminder,
      ),
    );
  }
}

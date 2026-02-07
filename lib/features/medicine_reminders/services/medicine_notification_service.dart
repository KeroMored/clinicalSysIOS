import 'package:flutter/material.dart' show Color;
import 'package:awesome_notifications/awesome_notifications.dart';
import '../data/models/medicine_model.dart';

class MedicineNotificationService {
  static const String channelKey = 'medicine_reminders';
  static const String channelName = 'تذكير الأدوية';
  static const String channelDescription = 'إشعارات لتذكيرك بمواعيد أدويتك';

  // Initialize notification channel
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // default icon
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: channelName,
          channelDescription: channelDescription,
          defaultColor: const Color(0xFF06B6D4),
          ledColor: const Color(0xFF06B6D4),
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          criticalAlerts: true,
          // Alarm settings
          soundSource: 'resource://raw/alarm_sound', // سيتم إضافة ملف صوت
          locked: true, // يبقى ظاهر حتى يتم إيقافه
        ),
      ],
    );
    
    // Request permissions for alarms
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  // Schedule notifications for a medicine
  static Future<void> scheduleMedicineNotifications(MedicineModel medicine) async {
    // Cancel existing notifications for this medicine first
    await cancelMedicineNotifications(medicine.id);
    
    // Don't schedule if medicine is not active
    if (!medicine.isActive) {
      return;
    }

    // Schedule notifications for each time
    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final timeString = medicine.reminderTimes[i];
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Generate unique notification ID
      final notificationId = _generateNotificationId(medicine.id, i);

      // Create notification schedule based on repeat type
      NotificationSchedule? schedule;
      bool needsDefaultSchedule = true; // Flag to check if we need default schedule
      
      switch (medicine.repeatType) {
        case RepeatType.daily:
          schedule = NotificationCalendar(
            hour: hour,
            minute: minute,
            second: 0,
            repeats: true,
          );
          break;

        case RepeatType.weekly:
          // Schedule for each selected day
          if (medicine.specificDays != null && medicine.specificDays!.isNotEmpty) {
            for (final weekday in medicine.specificDays!) {
              final weekdayNotificationId = _generateNotificationId(medicine.id, (i * 10 + weekday).toInt());
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: weekdayNotificationId,
                  channelKey: channelKey,
                  title: '🔔 موعد الدواء',
                  body: 'حان موعد ${medicine.displayName}',
                  notificationLayout: NotificationLayout.Default,
                  category: NotificationCategory.Alarm,
                  wakeUpScreen: true,
                  fullScreenIntent: true,
                  autoDismissible: false,
                  backgroundColor: const Color(0xFF06B6D4),
                  payload: {
                    'medicineId': medicine.id,
                    'medicineName': medicine.displayName,
                    'action': 'alarm',
                  },
                ),
                actionButtons: [
                  NotificationActionButton(
                    key: 'STOP',
                    label: 'تم أخذ الدواء ✓',
                    actionType: ActionType.DismissAction,
                    color: const Color(0xFF10B981),
                    autoDismissible: true,
                  ),
                ],
                schedule: NotificationCalendar(
                  hour: hour,
                  minute: minute,
                  second: 0,
                  weekday: weekday,
                  repeats: true,
                ),
              );
            }
            needsDefaultSchedule = false; // We already created notifications
          }
          break;
          
        case RepeatType.monthly:
          if (medicine.monthlyDay != null) {
            schedule = NotificationCalendar(
              hour: hour,
              minute: minute,
              second: 0,
              day: medicine.monthlyDay,
              repeats: true,
            );
          }
          break;

        case RepeatType.specificDays:
          // Similar to weekly
          if (medicine.specificDays != null && medicine.specificDays!.isNotEmpty) {
            for (final weekday in medicine.specificDays!) {
              final weekdayNotificationId = _generateNotificationId(medicine.id, (i * 10 + weekday).toInt());
              await AwesomeNotifications().createNotification(
                content: NotificationContent(
                  id: weekdayNotificationId,
                  channelKey: channelKey,
                  title: '🔔 موعد الدواء',
                  body: 'حان موعد ${medicine.displayName}',
                  notificationLayout: NotificationLayout.Default,
                  category: NotificationCategory.Alarm,
                  wakeUpScreen: true,
                  fullScreenIntent: true,
                  autoDismissible: false,
                  backgroundColor: const Color(0xFF06B6D4),
                  payload: {
                    'medicineId': medicine.id,
                    'medicineName': medicine.displayName,
                    'action': 'alarm',
                  },
                ),
                actionButtons: [
                  NotificationActionButton(
                    key: 'STOP',
                    label: 'تم أخذ الدواء ✓',
                    actionType: ActionType.DismissAction,
                    color: const Color(0xFF10B981),
                    autoDismissible: true,
                  ),
                ],
                schedule: NotificationCalendar(
                  hour: hour,
                  minute: minute,
                  second: 0,
                  weekday: weekday,
                  repeats: true,
                ),
              );
            }
            needsDefaultSchedule = false; // We already created notifications
          }
          break;
      }

      // Create notification if schedule was set (for daily and monthly)
      if (needsDefaultSchedule && schedule != null) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: channelKey,
            title: '🔔 موعد الدواء',
            body: 'حان موعد ${medicine.displayName}',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Alarm,
            wakeUpScreen: true,
            fullScreenIntent: true,
            autoDismissible: false,
            backgroundColor: const Color(0xFF06B6D4),
            payload: {
              'medicineId': medicine.id,
              'medicineName': medicine.displayName,
              'action': 'alarm',
            },
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'STOP',
              label: 'تم أخذ الدواء ✓',
              actionType: ActionType.DismissAction,
              color: const Color(0xFF10B981),
              autoDismissible: true,
            ),
          ],
          schedule: schedule,
        );
      }
    }
  }

  // Cancel all notifications for a medicine
  static Future<void> cancelMedicineNotifications(String medicineId) async {
    // Cancel all possible notification IDs for this medicine
    final baseId = medicineId.hashCode;
    for (int i = 0; i < 100; i++) {
      // Cancel up to 100 possible notification IDs (enough for most cases)
      final notificationId = (baseId + i).abs() % 2147483647;
      await AwesomeNotifications().cancel(notificationId);
    }
  }

  // Generate unique notification ID from medicine ID and index
  static int _generateNotificationId(String medicineId, int index) {
    final baseId = medicineId.hashCode;
    final combinedId = (baseId + index).abs();
    // Ensure ID is within valid range (int32)
    return combinedId % 2147483647;
  }

  // Update medicine notifications (cancel old and schedule new)
  static Future<void> updateMedicineNotifications(MedicineModel medicine) async {
    await cancelMedicineNotifications(medicine.id);
    if (medicine.isActive) {
      await scheduleMedicineNotifications(medicine);
    }
  }

  // Get scheduled notifications count
  static Future<int> getScheduledNotificationsCount() async {
    final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();
    return scheduledNotifications.where((n) => n.content?.channelKey == channelKey).length;
  }
}

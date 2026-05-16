import 'dart:io';

import 'package:flutter/material.dart' show Color;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../data/models/medicine_model.dart';

class MedicineNotificationService {
  static const String channelKey = 'medicine_reminders';
  static const String channelName = 'تذكير الأدوية';
  static const String channelDescription = 'إشعارات لتذكيرك بمواعيد أدويتك';
  static bool _isInitialized = false;

  static const String requestFollowUpChannelKey = 'medicine_request_followup';
  static const String _medicineImagesFolder = 'medicine_notification_images';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await AwesomeNotifications().initialize(
      null,
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
          locked: true,
        ),
        NotificationChannel(
          channelKey: requestFollowUpChannelKey,
          channelName: 'متابعة طلبات الدواء',
          channelDescription: 'تذكير بتأكيد التواصل مع الصيدلية',
          defaultColor: const Color(0xFF00BCD4),
          ledColor: const Color(0xFF00BCD4),
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    await _ensureExactAlarmPermission();

    _isInitialized = true;
  }

  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    await initialize();
  }

  static Future<void> scheduleMedicineNotifications(
    MedicineModel medicine,
  ) async {
    await _ensureInitialized();

    await cancelMedicineNotifications(medicine.id);

    if (!medicine.isActive) {
      return;
    }

    final localImagePath = await _cacheMedicineImageForNotifications(medicine);

    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final timeString = medicine.reminderTimes[i];
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final notificationId = _generateNotificationId(medicine.id, i);

      NotificationSchedule? schedule;
      bool needsDefaultSchedule = true;

      switch (medicine.repeatType) {
        case RepeatType.daily:
          schedule = NotificationCalendar(
            hour: hour,
            minute: minute,
            second: 0,
            repeats: true,
            allowWhileIdle: true,
            preciseAlarm: true,
          );
          break;

        case RepeatType.weekly:
          if (medicine.specificDays != null &&
              medicine.specificDays!.isNotEmpty) {
            for (final weekday in medicine.specificDays!) {
              final weekdayNotificationId = _generateNotificationId(
                medicine.id,
                (i * 10 + weekday).toInt(),
              );
              await AwesomeNotifications().createNotification(
                content: _buildMedicineReminderContent(
                  id: weekdayNotificationId,
                  medicine: medicine,
                  localImagePath: localImagePath,
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
                  allowWhileIdle: true,
                  preciseAlarm: true,
                ),
              );
            }
            needsDefaultSchedule = false;
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
              allowWhileIdle: true,
              preciseAlarm: true,
            );
          }
          break;

        case RepeatType.specificDays:
          if (medicine.specificDays != null &&
              medicine.specificDays!.isNotEmpty) {
            for (final weekday in medicine.specificDays!) {
              final weekdayNotificationId = _generateNotificationId(
                medicine.id,
                (i * 10 + weekday).toInt(),
              );
              await AwesomeNotifications().createNotification(
                content: _buildMedicineReminderContent(
                  id: weekdayNotificationId,
                  medicine: medicine,
                  localImagePath: localImagePath,
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
                  allowWhileIdle: true,
                  preciseAlarm: true,
                ),
              );
            }
            needsDefaultSchedule = false;
          }
          break;
      }

      if (needsDefaultSchedule && schedule != null) {
        await AwesomeNotifications().createNotification(
          content: _buildMedicineReminderContent(
            id: notificationId,
            medicine: medicine,
            localImagePath: localImagePath,
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

  static Future<void> cancelMedicineNotifications(String medicineId) async {
    final baseId = medicineId.hashCode;
    for (int i = 0; i < 100; i++) {
      final notificationId = (baseId + i).abs() % 2147483647;
      await AwesomeNotifications().cancel(notificationId);
    }
  }

  static Future<void> removeMedicineLocalAssets(String medicineId) async {
    final imageFile = await _localImageFileForMedicine(medicineId);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  static int _generateNotificationId(String medicineId, int index) {
    final baseId = medicineId.hashCode;
    final combinedId = (baseId + index).abs();
    return combinedId % 2147483647;
  }

  static Future<void> updateMedicineNotifications(
    MedicineModel medicine,
  ) async {
    await _ensureInitialized();
    await cancelMedicineNotifications(medicine.id);
    if (medicine.isActive) {
      await scheduleMedicineNotifications(medicine);
    }
  }

  static Future<int> getScheduledNotificationsCount() async {
    final scheduledNotifications =
        await AwesomeNotifications().listScheduledNotifications();
    return scheduledNotifications
        .where((n) => n.content?.channelKey == channelKey)
        .length;
  }

  static Future<void> scheduleMedicineRequestFollowUp(String requestId) async {
    await _ensureInitialized();

    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelKey: requestFollowUpChannelKey,
        channelName: 'متابعة طلبات الدواء',
        channelDescription: 'تذكير بتأكيد التواصل مع الصيدلية',
        defaultColor: const Color(0xFF00BCD4),
        ledColor: const Color(0xFF00BCD4),
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
    );
    final immediateNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 1,
    );
    final dayLaterNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 2,
    );

    await AwesomeNotifications().cancel(immediateNotificationId);
    await AwesomeNotifications().cancel(dayLaterNotificationId);

    final immediateTime = DateTime.now().add(const Duration(seconds: 3));
    final dayLaterTime = DateTime.now().add(const Duration(hours: 24));

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: immediateNotificationId,
        channelKey: requestFollowUpChannelKey,
        title: '🛒 تذكير سريع بطلب الدواء',
        body:
            'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك.',
        notificationLayout: NotificationLayout.BigText,
        autoDismissible: true,
        payload: {
          'type': 'medicine_request_followup',
          'requestId': requestId,
          'slot': 'immediate',
        },
      ),
      schedule: NotificationCalendar.fromDate(
        date: immediateTime,
        repeats: false,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: dayLaterNotificationId,
        channelKey: requestFollowUpChannelKey,
        title: '🛒 تذكير: هل تواصلت معك صيدلية؟',
        body:
            'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك حتى لا تزعجك صيدليات أخرى.',
        notificationLayout: NotificationLayout.BigText,
        autoDismissible: true,
        payload: {
          'type': 'medicine_request_followup',
          'requestId': requestId,
          'slot': 'day_later',
        },
      ),
      schedule: NotificationCalendar.fromDate(
        date: dayLaterTime,
        repeats: false,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  static Future<void> cancelMedicineRequestFollowUp(String requestId) async {
    final immediateNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 1,
    );
    final dayLaterNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 2,
    );
    await AwesomeNotifications().cancel(immediateNotificationId);
    await AwesomeNotifications().cancel(dayLaterNotificationId);
  }

  static Future<void> _ensureExactAlarmPermission() async {
    try {
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) return;

      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [NotificationPermission.PreciseAlarms],
      );
    } catch (_) {
      return;
    }
  }

  static int _generateRequestFollowUpId(String requestId, {required int slot}) {
    final base = 900000000 + requestId.hashCode.abs();
    return (base + slot) % 2147483647;
  }

  static NotificationContent _buildMedicineReminderContent({
    required int id,
    required MedicineModel medicine,
    String? localImagePath,
  }) {
    final imageForNotification =
        (localImagePath != null && localImagePath.trim().isNotEmpty)
            ? localImagePath
            : medicine.imageUrl;
    final hasImage =
        imageForNotification != null && imageForNotification.trim().isNotEmpty;

    return NotificationContent(
      id: id,
      channelKey: channelKey,
      title: '🔔 موعد الدواء',
      body: 'حان موعد ${medicine.displayName}',
      notificationLayout:
          hasImage ? NotificationLayout.BigPicture : NotificationLayout.Default,
      bigPicture: hasImage ? imageForNotification : null,
      largeIcon: hasImage ? imageForNotification : null,
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
    );
  }

  static Future<File> _localImageFileForMedicine(String medicineId) async {
    final supportDir = await getApplicationSupportDirectory();
    final safeId = medicineId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final folder = Directory('${supportDir.path}/$_medicineImagesFolder');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}/$safeId.jpg');
  }

  static Future<String?> _cacheMedicineImageForNotifications(
    MedicineModel medicine,
  ) async {
    final imageUrl = medicine.imageUrl?.trim();
    final localFile = await _localImageFileForMedicine(medicine.id);

    if (imageUrl == null || imageUrl.isEmpty) {
      if (await localFile.exists()) {
        await localFile.delete();
      }
      return null;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await localFile.writeAsBytes(response.bodyBytes, flush: true);
        return localFile.path;
      }
    } catch (_) {
      return localFile.existsSync() ? localFile.path : imageUrl;
    }

    if (await localFile.exists()) {
      return localFile.path;
    }

    return imageUrl;
  }
}
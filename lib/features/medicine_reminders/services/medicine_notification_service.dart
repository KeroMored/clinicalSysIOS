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

  // Channel خاص بمتابعة طلبات الدواء
  static const String requestFollowUpChannelKey = 'medicine_request_followup';
  static const String _medicineImagesFolder = 'medicine_notification_images';

  // Initialize notification channel
  static Future<void> initialize() async {
    if (_isInitialized) return;

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
          locked: true, // يبقى ظاهر حتى يتم إيقافه
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

    // Request permissions for alarms
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

  // Schedule notifications for a medicine
  static Future<void> scheduleMedicineNotifications(
    MedicineModel medicine,
  ) async {
    await _ensureInitialized();

    // Cancel existing notifications for this medicine first
    await cancelMedicineNotifications(medicine.id);

    // Don't schedule if medicine is not active
    if (!medicine.isActive) {
      return;
    }

    final localImagePath = await _cacheMedicineImageForNotifications(medicine);

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
      bool needsDefaultSchedule =
          true; // Flag to check if we need default schedule

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
          // Schedule for each selected day
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
              allowWhileIdle: true,
              preciseAlarm: true,
            );
          }
          break;

        case RepeatType.specificDays:
          // Similar to weekly
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
            needsDefaultSchedule = false; // We already created notifications
          }
          break;
      }

      // Create notification if schedule was set (for daily and monthly)
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

  /// Remove local cached image for a medicine from device storage.
  static Future<void> removeMedicineLocalAssets(String medicineId) async {
    final imageFile = await _localImageFileForMedicine(medicineId);
    if (await imageFile.exists()) {
      await imageFile.delete();
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
  static Future<void> updateMedicineNotifications(
    MedicineModel medicine,
  ) async {
    await _ensureInitialized();
    await cancelMedicineNotifications(medicine.id);
    if (medicine.isActive) {
      await scheduleMedicineNotifications(medicine);
    }
  }

  // Get scheduled notifications count
  static Future<int> getScheduledNotificationsCount() async {
    final scheduledNotifications = await AwesomeNotifications()
        .listScheduledNotifications();
    return scheduledNotifications
        .where((n) => n.content?.channelKey == channelKey)
        .length;
  }

  /// جدولة إشعارين متابعة لطلب الدواء:
  /// - الأول بعد 3 ثواني من إنشاء الطلب
  /// - الثاني بعد 24 ساعة
  /// كلاهما مرة واحدة فقط ولا يتكرران
  static Future<void> scheduleMedicineRequestFollowUp(String requestId) async {
    await _ensureInitialized();

    // نضمن وجود الـ channel حتى لو التطبيق اتنصب قبل إضافته
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

    // إلغاء أي إشعارات سابقة لنفس الطلب (لتجنب التكرار)
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

  /// إلغاء إشعار المتابعة الخاص بطلب معين (مثلاً بعد الضغط على "تم التواصل")
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
      // Best effort only: alarm permission prompt behavior differs by Android API.
    }
  }

  static int _generateRequestFollowUpId(String requestId, {required int slot}) {
    // نستخدم نطاق مختلف عن تذكيرات الدواء (نبدأ من 900_000_000)
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
      notificationLayout: hasImage
          ? NotificationLayout.BigPicture
          : NotificationLayout.Default,
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

    // If medicine has no image, remove stale local cache if found.
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
      // Fall back to previously cached file if available.
    }

    if (await localFile.exists()) {
      return localFile.path;
    }

    // Last fallback when no cache exists yet.
    return imageUrl;
  }
}

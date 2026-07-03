import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/medicine_model.dart';

class MedicineNotificationService {
  static const String channelKey = 'medicine_reminders';
  static const String channelName = 'تذكير الأدوية';
  static const String channelDescription = 'إشعارات لتذكيرك بمواعيد أدويتك';

  static const String requestFollowUpChannelKey = 'medicine_request_followup';
  static const String _medicineImagesFolder = 'medicine_notification_images';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsReady = false;
  static bool _timeZonesReady = false;

  static Future<void> initialize() async {
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

    const medicineChannel = AndroidNotificationChannel(
      channelKey,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const followUpChannel = AndroidNotificationChannel(
      requestFollowUpChannelKey,
      'متابعة طلبات الدواء',
      description: 'تذكير بتأكيد التواصل مع الصيدلية',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(medicineChannel);
    await androidPlugin?.createNotificationChannel(followUpChannel);
    await androidPlugin?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _ensureExactAlarmPermission();

    _localNotificationsReady = true;
  }

  static Future<void> _ensureInitialized() async {
    if (_localNotificationsReady) return;
    await initialize();
  }

  static void _ensureTimeZonesReady() {
    if (_timeZonesReady) return;
    tz.initializeTimeZones();
    _timeZonesReady = true;
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    _ensureTimeZonesReady();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfWeekday(
    int weekday,
    int hour,
    int minute,
  ) {
    _ensureTimeZonesReady();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static int _daysInMonth(int year, int month) {
    final beginningNextMonth = DateTime(year, month + 1, 1);
    final lastDay = beginningNextMonth.subtract(const Duration(days: 1));
    return lastDay.day;
  }

  static tz.TZDateTime _nextInstanceOfMonthDay(
    int day,
    int hour,
    int minute,
  ) {
    _ensureTimeZonesReady();
    final now = tz.TZDateTime.now(tz.local);
    final maxDay = _daysInMonth(now.year, now.month);
    final safeDay = day.clamp(1, maxDay);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      safeDay,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextMonthMaxDay = _daysInMonth(nextMonth.year, nextMonth.month);
      final nextSafeDay = day.clamp(1, nextMonthMaxDay);
      scheduledDate = tz.TZDateTime(
        tz.local,
        nextMonth.year,
        nextMonth.month,
        nextSafeDay,
        hour,
        minute,
      );
    }
    return scheduledDate;
  }

  static NotificationDetails _buildMedicineNotificationDetails({
    required String title,
    required String body,
    String? localImagePath,
  }) {
    final hasLocalImage =
        localImagePath != null &&
        localImagePath.trim().isNotEmpty &&
        File(localImagePath).existsSync();

    final styleInformation = hasLocalImage
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(localImagePath),
            contentTitle: title,
            summaryText: body,
          )
        : BigTextStyleInformation(
            body,
            contentTitle: title,
          );

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelKey,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF06B6D4),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: styleInformation,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  static NotificationDetails _buildFollowUpNotificationDetails({
    required String title,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        requestFollowUpChannelKey,
        'متابعة طلبات الدواء',
        channelDescription: 'تذكير بتأكيد التواصل مع الصيدلية',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF00BCD4),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
        ),
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }

  static Future<void> _scheduleMedicineNotification({
    required int id,
    required MedicineModel medicine,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
    String? localImagePath,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _buildMedicineNotificationDetails(
        title: title,
        body: body,
        localImagePath: localImagePath,
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: jsonEncode({
        'type': 'medicine_reminder',
        'medicineId': medicine.id,
        'medicineName': medicine.displayName,
      }),
    );
  }

  static Future<void> scheduleMedicineNotifications(
    MedicineModel medicine,
  ) async {
    await _ensureInitialized();
    _ensureTimeZonesReady();

    await cancelMedicineNotifications(medicine.id);

    if (!medicine.isActive) {
      return;
    }

    final localImagePath = await _cacheMedicineImageForNotifications(medicine);
    final title = '🔔 موعد الدواء';
    final body = 'حان موعد ${medicine.displayName}';

    for (int i = 0; i < medicine.reminderTimes.length; i++) {
      final timeString = medicine.reminderTimes[i];
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final notificationId = _generateNotificationId(medicine.id, i);

      switch (medicine.repeatType) {
        case RepeatType.daily:
          await _scheduleMedicineNotification(
            id: notificationId,
            medicine: medicine,
            scheduledDate: _nextInstanceOfTime(hour, minute),
            title: title,
            body: body,
            localImagePath: localImagePath,
            matchDateTimeComponents: DateTimeComponents.time,
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
              await _scheduleMedicineNotification(
                id: weekdayNotificationId,
                medicine: medicine,
                scheduledDate: _nextInstanceOfWeekday(
                  weekday,
                  hour,
                  minute,
                ),
                title: title,
                body: body,
                localImagePath: localImagePath,
                matchDateTimeComponents:
                    DateTimeComponents.dayOfWeekAndTime,
              );
            }
          }
          break;

        case RepeatType.monthly:
          if (medicine.monthlyDay != null) {
            await _scheduleMedicineNotification(
              id: notificationId,
              medicine: medicine,
              scheduledDate: _nextInstanceOfMonthDay(
                medicine.monthlyDay!,
                hour,
                minute,
              ),
              title: title,
              body: body,
              localImagePath: localImagePath,
              matchDateTimeComponents:
                  DateTimeComponents.dayOfMonthAndTime,
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
              await _scheduleMedicineNotification(
                id: weekdayNotificationId,
                medicine: medicine,
                scheduledDate: _nextInstanceOfWeekday(
                  weekday,
                  hour,
                  minute,
                ),
                title: title,
                body: body,
                localImagePath: localImagePath,
                matchDateTimeComponents:
                    DateTimeComponents.dayOfWeekAndTime,
              );
            }
          }
          break;
      }
    }
  }

  static Future<void> cancelMedicineNotifications(String medicineId) async {
    final baseId = medicineId.hashCode;
    for (int i = 0; i < 100; i++) {
      final notificationId = (baseId + i).abs() % 2147483647;
      await _localNotifications.cancel(notificationId);
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

  static String? _payloadType(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['type'] is String) {
        return decoded['type'] as String;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<int> getScheduledNotificationsCount() async {
    await _ensureInitialized();
    final scheduled = await _localNotifications.pendingNotificationRequests();
    return scheduled
        .where((request) => _payloadType(request.payload) == 'medicine_reminder')
        .length;
  }

  static Future<void> scheduleMedicineRequestFollowUp(String requestId) async {
    await _ensureInitialized();
    _ensureTimeZonesReady();

    final immediateNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 1,
    );
    final dayLaterNotificationId = _generateRequestFollowUpId(
      requestId,
      slot: 2,
    );

    await _localNotifications.cancel(immediateNotificationId);
    await _localNotifications.cancel(dayLaterNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    final immediateTime = now.add(const Duration(seconds: 3));
    final dayLaterTime = now.add(const Duration(hours: 24));

    await _localNotifications.zonedSchedule(
      immediateNotificationId,
      '🛒 تذكير سريع بطلب الدواء',
      'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك.',
      immediateTime,
      _buildFollowUpNotificationDetails(
        title: '🛒 تذكير سريع بطلب الدواء',
        body:
            'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك.',
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'medicine_request_followup',
        'requestId': requestId,
        'slot': 'immediate',
      }),
    );

    await _localNotifications.zonedSchedule(
      dayLaterNotificationId,
      '🛒 تذكير: هل تواصلت معك صيدلية؟',
      'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك حتى لا تزعجك صيدليات أخرى.',
      dayLaterTime,
      _buildFollowUpNotificationDetails(
        title: '🛒 تذكير: هل تواصلت معك صيدلية؟',
        body:
            'لو في صيدلية اتواصلت معاك، افتح السلة واضغط "تم التواصل" على طلبك حتى لا تزعجك صيدليات أخرى.',
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'medicine_request_followup',
        'requestId': requestId,
        'slot': 'day_later',
      }),
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
    await _localNotifications.cancel(immediateNotificationId);
    await _localNotifications.cancel(dayLaterNotificationId);
  }

  static Future<void> _ensureExactAlarmPermission() async {
    try {
      final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
      await android?.requestExactAlarmsPermission();
      await android?.requestFullScreenIntentPermission();
    } catch (_) {
      return;
    }
  }

  static int _generateRequestFollowUpId(String requestId, {required int slot}) {
    final base = 900000000 + requestId.hashCode.abs();
    return (base + slot) % 2147483647;
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
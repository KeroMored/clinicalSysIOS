import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/laboratory/data/models/appointment_model.dart';
import '../../features/laboratory/data/repositories/lab_tests_repository.dart';

/// خدمة التذكيرات التلقائية للمواعيد
class AppointmentReminderService {
  static final AppointmentReminderService _instance =
      AppointmentReminderService._internal();
  factory AppointmentReminderService() => _instance;
  AppointmentReminderService._internal();

  static const String _channelId = 'appointment_reminders';
  static const String _channelName = 'تذكيرات المواعيد';
  static const String _channelDescription = 'إشعارات تذكير بمواعيد التحاليل';

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _localNotificationsReady = false;
  static bool _timeZonesReady = false;

  Timer? _reminderTimer;
  final LabTestsRepository _repository = LabTestsRepository();

  /// تهيئة خدمة التذكيرات
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
      _channelId,
      _channelName,
      description: _channelDescription,
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

  /// بدء خدمة التذكيرات التلقائية (تعمل كل 15 دقيقة)
  void startReminderService() {
    stopReminderService(); // إيقاف أي timer سابق

    // فحص فوري عند البدء
    _checkAndSendReminders();

    // جدولة فحص دوري كل 15 دقيقة
    _reminderTimer = Timer.periodic(
      Duration(minutes: 15),
      (timer) => _checkAndSendReminders(),
    );

    print('Appointment Reminder Service Started');
  }

  /// إيقاف خدمة التذكيرات
  void stopReminderService() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    print('Appointment Reminder Service Stopped');
  }

  /// فحص وإرسال التذكيرات للمواعيد القادمة
  Future<void> _checkAndSendReminders() async {
    try {
      final appointments = await _repository.getAppointmentsNeedingReminders();

      for (var appointment in appointments) {
        if (appointment.needsReminder24Hours) {
          await _send24HourReminder(appointment);
          await _repository.sendAppointmentReminder(
            appointment.id,
            AppointmentModel.reminder24Hours,
          );
        } else if (appointment.needsReminder1Hour) {
          await _send1HourReminder(appointment);
          await _repository.sendAppointmentReminder(
            appointment.id,
            AppointmentModel.reminder1Hour,
          );
        }
      }

      if (appointments.isNotEmpty) {
        print(
          'Sent ${appointments.length} appointment reminders at ${DateTime.now()}',
        );
      }
    } catch (e) {
      print('Error checking reminders: $e');
    }
  }

  static NotificationDetails _buildNotificationDetails({
    required String title,
    required String body,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
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

  /// إرسال تذكير 24 ساعة
  Future<void> _send24HourReminder(AppointmentModel appointment) async {
    await _ensureLocalNotificationsReady();

    final title = '🔔 تذكير: موعد غداً';
    final body =
        'لديك موعد غداً لإجراء ${appointment.testName} في ${appointment.laboratoryName}';

    await _localNotifications.show(
      appointment.id.hashCode,
      title,
      body,
      _buildNotificationDetails(title: title, body: body),
      payload: jsonEncode({
        'type': 'appointment_reminder',
        'appointmentId': appointment.id,
        'reminderType': '24h',
      }),
    );
  }

  /// إرسال تذكير ساعة واحدة
  Future<void> _send1HourReminder(AppointmentModel appointment) async {
    await _ensureLocalNotificationsReady();

    final formattedTime =
        '${appointment.appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointment.appointmentDateTime.minute.toString().padLeft(2, '0')}';
    final title = '⏰ موعدك بعد ساعة!';
    final body =
        'موعدك لإجراء ${appointment.testName} في تمام الساعة $formattedTime';

    await _localNotifications.show(
      appointment.id.hashCode + 1,
      title,
      body,
      _buildNotificationDetails(title: title, body: body),
      payload: jsonEncode({
        'type': 'appointment_reminder',
        'appointmentId': appointment.id,
        'reminderType': '1h',
      }),
    );
  }

  // /// جدولة تذكير مخصص لموعد محدد
  Future<void> scheduleCustomReminder(
    AppointmentModel appointment,
    Duration beforeAppointment,
    String message,
  ) async {
    final reminderTime = appointment.appointmentDateTime.subtract(
      beforeAppointment,
    );

    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    await _ensureLocalNotificationsReady();
    _ensureTimeZonesReady();

    await _localNotifications.zonedSchedule(
      appointment.id.hashCode + beforeAppointment.inMinutes,
      'تذكير بموعد التحليل',
      message,
      tz.TZDateTime.from(reminderTime, tz.local),
      _buildNotificationDetails(title: 'تذكير بموعد التحليل', body: message),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'custom_reminder',
        'appointmentId': appointment.id,
      }),
    );
  }

  // /// جدولة تذكيرات دورية (مثل: تحليل السكر كل 3 شهور)
  Future<void> scheduleRecurringReminder({
    required String testName,
    required Duration interval,
    DateTime? startDate,
  }) async {
    await _ensureLocalNotificationsReady();

    final title = '📋 تذكير: حان وقت إجراء التحليل';
    final body = 'حان وقت إجراء $testName الدوري';

    await _localNotifications.periodicallyShowWithDuration(
      testName.hashCode,
      title,
      body,
      interval,
      _buildNotificationDetails(title: title, body: body),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'recurring_reminder',
        'testName': testName,
      }),
    );
  }

  // /// إلغاء تذكير معين
  Future<void> cancelReminder(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }

  // /// إلغاء جميع تذكيرات موعد معين
  Future<void> cancelAppointmentReminders(String appointmentId) async {
    await _localNotifications.cancel(appointmentId.hashCode);
    await _localNotifications.cancel(appointmentId.hashCode + 1);
  }

  // /// الحصول على جميع التذكيرات المجدولة
  Future<List<PendingNotificationRequest>> getScheduledReminders() async {
    return _localNotifications.pendingNotificationRequests();
  }

  // /// إلغاء جميع التذكيرات
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
  }
}


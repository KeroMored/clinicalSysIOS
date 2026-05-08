import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:awesome_notifications/awesome_notifications.dart';
import '../../features/laboratory/data/repositories/lab_tests_repository.dart';
import '../../features/laboratory/data/models/appointment_model.dart';

/// خدمة التذكيرات التلقائية للمواعيد
class AppointmentReminderService {
  static final AppointmentReminderService _instance =
      AppointmentReminderService._internal();
  factory AppointmentReminderService() => _instance;
  AppointmentReminderService._internal();

  Timer? _reminderTimer;
  final LabTestsRepository _repository = LabTestsRepository();

  /// تهيئة خدمة التذكيرات
  // static Future<void> initialize() async {
  //   await AwesomeNotifications().initialize(null, [
  //     NotificationChannel(
  //       channelKey: 'appointment_reminders',
  //       channelName: 'تذكيرات المواعيد',
  //       channelDescription: 'إشعارات تذكير بمواعيد التحاليل',
  //       defaultColor: Color(0xFF00BCD4),
  //       ledColor: Colors.white,
  //       importance: NotificationImportance.High,
  //       playSound: true,
  //       enableVibration: true,
  //     ),
  //   ]);

  //   // طلب الأذونات
  //   await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  //     if (!isAllowed) {
  //       AwesomeNotifications().requestPermissionToSendNotifications();
  //     }
  //   });
  // }

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
         // await _send24HourReminder(appointment);
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

  /// إرسال تذكير 24 ساعة
  // Future<void> _send24HourReminder(AppointmentModel appointment) async {
  //   await AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: appointment.id.hashCode,
  //       channelKey: 'appointment_reminders',
  //       title: '🔔 تذكير: موعد غداً',
  //       body:
  //           'لديك موعد غداً لإجراء ${appointment.testName} في ${appointment.laboratoryName}',
  //       bigPicture: 'asset://assets/images/lab_icon.png',
  //       notificationLayout: NotificationLayout.BigPicture,
  //       payload: {
  //         'type': 'appointment_reminder',
  //         'appointmentId': appointment.id,
  //         'reminderType': '24h',
  //       },
  //     ),
  //     actionButtons: [
  //       NotificationActionButton(key: 'VIEW', label: 'عرض التفاصيل'),
  //       NotificationActionButton(
  //         key: 'CANCEL',
  //         label: 'إلغاء',
  //         actionType: ActionType.DismissAction,
  //       ),
  //     ],
  //   );
  // }

  /// إرسال تذكير ساعة واحدة
  Future<void> _send1HourReminder(AppointmentModel appointment) async {
    final formattedTime =
        '${appointment.appointmentDateTime.hour.toString().padLeft(2, '0')}:${appointment.appointmentDateTime.minute.toString().padLeft(2, '0')}';

    // await AwesomeNotifications().createNotification(
    //   content: NotificationContent(
    //     id: appointment.id.hashCode + 1, // ID مختلف عن تذكير 24 ساعة
    //     channelKey: 'appointment_reminders',
    //     title: '⏰ موعدك بعد ساعة!',
    //     body:
    //         'موعدك لإجراء ${appointment.testName} في تمام الساعة $formattedTime',
    //     bigPicture: 'asset://assets/images/lab_icon.png',
    //     notificationLayout: NotificationLayout.BigPicture,
    //     criticalAlert: true, // تنبيه هام
    //     payload: {
    //       'type': 'appointment_reminder',
    //       'appointmentId': appointment.id,
    //       'reminderType': '1h',
    //     },
    //   ),
    //   actionButtons: [
    //     NotificationActionButton(key: 'VIEW', label: 'عرض الموعد'),
    //     NotificationActionButton(
    //       key: 'DIRECTIONS',
    //       label: 'الاتجاهات',
    //       icon: 'resource://drawable/ic_directions',
    //     ),
    //   ],
    // );
  
  
  }

  // /// جدولة تذكير مخصص لموعد محدد
  // Future<void> scheduleCustomReminder(
  //   AppointmentModel appointment,
  //   Duration beforeAppointment,
  //   String message,
  // ) async {
  //   final reminderTime = appointment.appointmentDateTime.subtract(
  //     beforeAppointment,
  //   );

  //   // التأكد من أن الوقت في المستقبل
  //   if (reminderTime.isBefore(DateTime.now())) {
  //     return;
  //   }

  //   await AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: appointment.id.hashCode + beforeAppointment.inMinutes,
  //       channelKey: 'appointment_reminders',
  //       title: 'تذكير بموعد التحليل',
  //       body: message,
  //       payload: {'type': 'custom_reminder', 'appointmentId': appointment.id},
  //     ),
  //     schedule: NotificationCalendar.fromDate(date: reminderTime),
  //   );
  // }

  // /// جدولة تذكيرات دورية (مثل: تحليل السكر كل 3 شهور)
  // Future<void> scheduleRecurringReminder({
  //   required String testName,
  //   required Duration interval,
  //   DateTime? startDate,
  // }) async {
  //   final firstReminderDate = startDate ?? DateTime.now().add(interval);

  //   await AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: testName.hashCode,
  //       channelKey: 'appointment_reminders',
  //       title: '📋 تذكير: حان وقت إجراء التحليل',
  //       body: 'حان وقت إجراء $testName الدوري',
  //       payload: {'type': 'recurring_reminder', 'testName': testName},
  //     ),
  //     schedule: NotificationCalendar.fromDate(
  //       date: firstReminderDate,
  //       repeats: true,
  //     ),
  //   );
  // }

  // /// إلغاء تذكير معين
  // Future<void> cancelReminder(int notificationId) async {
  //   await AwesomeNotifications().cancel(notificationId);
  // }

  // /// إلغاء جميع تذكيرات موعد معين
  // Future<void> cancelAppointmentReminders(String appointmentId) async {
  //   await AwesomeNotifications().cancel(appointmentId.hashCode);
  //   await AwesomeNotifications().cancel(appointmentId.hashCode + 1);
  // }

  // /// الحصول على جميع التذكيرات المجدولة
  // Future<List<NotificationModel>> getScheduledReminders() async {
  //   return await AwesomeNotifications().listScheduledNotifications();
  // }

  // /// إلغاء جميع التذكيرات
  // Future<void> cancelAllReminders() async {
  //   await AwesomeNotifications().cancelAllSchedules();
  // }
}

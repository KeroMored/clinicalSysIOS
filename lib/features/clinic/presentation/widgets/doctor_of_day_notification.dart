//import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class DoctorOfTheDayNotification {
  static final DoctorOfTheDayNotification _instance =
      DoctorOfTheDayNotification._internal();
  factory DoctorOfTheDayNotification() => _instance;
  DoctorOfTheDayNotification._internal();

  // Initialize Awesome Notifications
  // static Future<void> initialize() async {
  //   await AwesomeNotifications().initialize(null, [
  //     NotificationChannel(
  //       channelKey: 'doctor_of_day_channel',
  //       channelName: 'دكتور اليوم',
  //       channelDescription: 'إشعارات دكتور اليوم اليومية',
  //       defaultColor: const Color(0xFF26A69A),
  //       ledColor: Colors.white,
  //       importance: NotificationImportance.High,
  //       playSound: true,
  //       enableVibration: true,
  //     ),
  //   ]);

  //   // Request permissions
  //   await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
  //     if (!isAllowed) {
  //       AwesomeNotifications().requestPermissionToSendNotifications();
  //     }
  //   });
  // }

  // Schedule daily notification at 4:05 PM Egypt time - Simple offline notification
  // static Future<void> scheduleDailyNotification() async {
  //   // Cancel only this feature schedule to avoid expensive global operations.
  //   await AwesomeNotifications().cancelSchedule(100);

  //   await AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: 100,
  //       channelKey: 'doctor_of_day_channel',
  //       title: '👨‍⚕️ دكتور اليوم',
  //       body: 'شوف دكتور النهاردة 💊',
  //       notificationLayout: NotificationLayout.Default,
  //       wakeUpScreen: true,
  //       category: NotificationCategory.Reminder,
  //     ),
  //     schedule: NotificationCalendar(
  //       hour: 19, // 7 PM
  //       minute: 00,
  //       second: 0,
  //       repeats: true, // Repeat daily
  //     ),
  //   );

  //   debugPrint('Daily notification scheduled for 7:00 PM');
  // }

  // // Get today's featured doctors (10 doctors with varied specializations)
  static Future<List<Map<String, dynamic>>> getTodaysFeaturedDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('status', isEqualTo: 'approved')
          .get();

      if (snapshot.docs.isEmpty) return [];

      // Use today's date as seed for consistent daily selection
      final today = DateTime.now();
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final random = Random(seed);

      // Group by specialization
      Map<String, List<QueryDocumentSnapshot>> bySpecialization = {};
      for (var doc in snapshot.docs) {
        final specData = doc.data()['specialization'];
        final spec = (specData is List && specData.isNotEmpty)
            ? specData.first.toString()
            : (specData?.toString() ?? 'عام');
        bySpecialization.putIfAbsent(spec, () => []).add(doc);
      }

      List<Map<String, dynamic>> selectedDoctors = [];
      List<String> usedSpecs = [];

      // Try to get 10 doctors from different specializations
      final specs = bySpecialization.keys.toList()..shuffle(random);

      for (var spec in specs) {
        if (selectedDoctors.length >= 10) break;
        if (!usedSpecs.contains(spec)) {
          final docs = bySpecialization[spec]!;
          final doc = docs[random.nextInt(docs.length)];
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          selectedDoctors.add(data);
          usedSpecs.add(spec);
        }
      }

      // If we have less than 10 doctors, fill with remaining doctors
      if (selectedDoctors.length < 10) {
        final remainingDocs = snapshot.docs.where((doc) {
          return !selectedDoctors.any((selected) => selected['id'] == doc.id);
        }).toList()..shuffle(random);

        for (var doc in remainingDocs) {
          if (selectedDoctors.length >= 10) break;
          final data = doc.data();
          data['id'] = doc.id;
          selectedDoctors.add(data);
        }
      }

      return selectedDoctors;
    } catch (e) {
      debugPrint('Error getting today\'s featured doctors: $e');
      return [];
    }
  }

  // Get today's featured doctor (for backward compatibility)
  static Future<Map<String, dynamic>?> getTodaysFeaturedDoctor() async {
    final doctors = await getTodaysFeaturedDoctors();
    return doctors.isNotEmpty ? doctors.first : null;
  }

  // // Send immediate test notification
  // static Future<void> sendTestNotification() async {
  //   await AwesomeNotifications().createNotification(
  //     content: NotificationContent(
  //       id: 101,
  //       channelKey: 'doctor_of_day_channel',
  //       title: '👨‍⚕️ دكتور اليوم',
  //       body: 'شوف دكتور النهاردة 💊',
  //       notificationLayout: NotificationLayout.Default,
  //       wakeUpScreen: true,
  //     ),
  //   );
  // }

  // Cancel all notifications
  // static Future<void> cancelAllNotifications() async {
  //   await AwesomeNotifications().cancelAll();
  // }

  // Check if notifications are enabled
  // static Future<bool> areNotificationsEnabled() async {
  //   return await AwesomeNotifications().isNotificationAllowed();
  // }

  // Request notification permission
  // static Future<bool> requestPermission() async {
  //   return await AwesomeNotifications().requestPermissionToSendNotifications();
  // }
}

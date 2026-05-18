import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DoctorOfTheDayNotification {
  static final DoctorOfTheDayNotification _instance =
      DoctorOfTheDayNotification._internal();
  factory DoctorOfTheDayNotification() => _instance;
  DoctorOfTheDayNotification._internal();

  static const String _channelId = 'doctor_of_day_channel';
  static const String _channelName = 'دكتور اليوم';
  static const String _channelDescription = 'إشعارات دكتور اليوم اليومية';

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

  static NotificationDetails _buildNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> scheduleDailyNotification() async {
    await _ensureLocalNotificationsReady();
    await _localNotifications.cancel(100);

    final scheduledDate = _nextInstanceOfTime(19, 0);

    await _localNotifications.zonedSchedule(
      100,
      '👨‍⚕️ دكتور اليوم',
      'شوف دكتور النهاردة 💊',
      scheduledDate,
      _buildNotificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Daily notification scheduled for 7:00 PM');
  }

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

  static Future<void> sendTestNotification() async {
    await _ensureLocalNotificationsReady();
    await _localNotifications.show(
      101,
      '👨‍⚕️ دكتور اليوم',
      'شوف دكتور النهاردة 💊',
      _buildNotificationDetails(),
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<bool> areNotificationsEnabled() async {
    await _ensureLocalNotificationsReady();
    final ios = _localNotifications.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin
    >();
    if (ios != null) {
      final status = await ios.checkPermissions();
      return status?.isEnabled ?? false;
    }

    return true;
  }

  static Future<bool> requestPermission() async {
    await _ensureLocalNotificationsReady();
    final ios = _localNotifications.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin
    >();
    if (ios != null) {
      return (await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          )) ??
          false;
    }

    final android = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    return (await android?.requestNotificationsPermission()) ?? true;
  }
}

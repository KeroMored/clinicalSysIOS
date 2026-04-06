import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Topic names
  static const String pharmacyTopic = 'pharmacy_requests';
  static const String allUsersTopic =
      'all_users'; // For general notifications (offers, etc.)

  /// Initialize notifications and request permissions
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request permission for iOS and Android 13+
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    print('📱 FCM Token: $token');
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // High importance channel
    const highChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Medicine requests channel
    const medicineChannel = AndroidNotificationChannel(
      'medicine_requests',
      'Medicine Requests',
      description: 'Notifications for new medicine requests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Clinic bookings channel
    const bookingsChannel = AndroidNotificationChannel(
      'clinic_bookings',
      'Clinic Bookings',
      description: 'Notifications for new online bookings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Medicine offers channel
    const offersChannel = AndroidNotificationChannel(
      'medicine_offers',
      'Medicine Offers',
      description: 'Notifications for special medicine offers',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Laboratory bookings channel
    const labBookingsChannel = AndroidNotificationChannel(
      'lab_bookings',
      'Laboratory Bookings',
      description: 'Notifications for new laboratory bookings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(medicineChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(bookingsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(offersChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(labBookingsChannel);

    print('✅ Notification channels created');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationAction(decoded);
      }
    } catch (_) {
      // Backward compatibility for old simple payloads.
    }
  }

  Future<void> _handleNotificationAction(Map<String, dynamic> data) async {
    final openUrl = (data['openUrl'] ?? '').toString().trim();
    if (openUrl.isEmpty) return;

    final uri = Uri.tryParse(openUrl);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Subscribe ALL users to the general topic for offers and announcements
  Future<void> subscribeToAllUsersTopic(String userId) async {
    try {
      await _messaging.subscribeToTopic(allUsersTopic);
      print('✅ Subscribed to all_users topic');

      // Get FCM token
      String? token = await _messaging.getToken();

      // Update user document with FCM token and topic subscription
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'subscribedToAllUsers': true,
        'allUsersTopicSubscribedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error subscribing to all_users topic: $e');
    }
  }

  /// Subscribe pharmacy owner to the topic
  Future<void> subscribeToPharmacyTopic(String userId) async {
    try {
      await _messaging.subscribeToTopic(pharmacyTopic);
      print('✅ Subscribed to pharmacy topic: $pharmacyTopic');

      // Get and print FCM token for debugging
      String? token = await _messaging.getToken();
      print('📱 FCM Token: $token');

      // Optional: Save subscription info in Firestore
      await _firestore.collection('pharmacy_subscriptions').doc(userId).set({
        'subscribedAt': FieldValue.serverTimestamp(),
        'topic': pharmacyTopic,
        'isActive': true,
        'fcmToken': token,
      });
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from pharmacy topic (when signing out)
  Future<void> unsubscribeFromPharmacyTopic(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic(pharmacyTopic);
      print('Unsubscribed from pharmacy topic');

      // Update Firestore
      await _firestore.collection('pharmacy_subscriptions').doc(userId).update({
        'unsubscribedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe clinic owner to clinic-specific topic for booking notifications
  Future<void> subscribeToClinicTopic(String clinicId, String userId) async {
    try {
      final clinicTopic = 'clinic_$clinicId';
      await _messaging.subscribeToTopic(clinicTopic);
      print('✅ Subscribed to clinic topic: $clinicTopic');

      // Get FCM token
      String? token = await _messaging.getToken();
      print('📱 FCM Token for clinic: $token');

      // Save subscription info and FCM token
      await _firestore.collection('clinic_subscriptions').doc(clinicId).set({
        'subscribedAt': FieldValue.serverTimestamp(),
        'topic': clinicTopic,
        'isActive': true,
        'fcmToken': token,
        'userId': userId,
      });

      // Also update user document with FCM token
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error subscribing to clinic topic: $e');
    }
  }

  /// Unsubscribe from clinic topic
  Future<void> unsubscribeFromClinicTopic(String clinicId) async {
    try {
      final clinicTopic = 'clinic_$clinicId';
      await _messaging.unsubscribeFromTopic(clinicTopic);
      print('Unsubscribed from clinic topic: $clinicTopic');

      // Update Firestore
      await _firestore.collection('clinic_subscriptions').doc(clinicId).update({
        'unsubscribedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
    } catch (e) {
      print('Error unsubscribing from clinic topic: $e');
    }
  }

  /// Subscribe secretary to multiple clinic topics (for secretaries working in multiple clinics)
  Future<void> subscribeToMultipleClinicTopics(
    List<String> clinicIds,
    String userId,
  ) async {
    try {
      // Get FCM token once
      final String? token = await _messaging.getToken();
      print('📱 FCM Token for secretary: $token');

      // Subscribe to each clinic topic
      for (var clinicId in clinicIds) {
        final clinicTopic = 'clinic_$clinicId';
        await _messaging.subscribeToTopic(clinicTopic);
        print('✅ Secretary subscribed to clinic topic: $clinicTopic');

        // Save subscription info
        await _firestore
            .collection('clinic_subscriptions')
            .doc('${userId}_$clinicId')
            .set({
              'subscribedAt': FieldValue.serverTimestamp(),
              'topic': clinicTopic,
              'isActive': true,
              'fcmToken': token,
              'userId': userId,
              'clinicId': clinicId,
              'role': 'secretary',
            });
      }

      // Update user document with FCM token
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
          'secretaryClinics': clinicIds,
        });
      }

      print(
        '✅ Secretary successfully subscribed to ${clinicIds.length} clinic topics',
      );
    } catch (e) {
      print('❌ Error subscribing secretary to clinic topics: $e');
    }
  }

  /// Subscribe laboratory owner to lab-specific topic for booking notifications
  Future<void> subscribeToLabTopic(String laboratoryId, String userId) async {
    try {
      final labTopic = 'lab_$laboratoryId';
      await _messaging.subscribeToTopic(labTopic);
      print('✅ Subscribed to laboratory topic: $labTopic');

      // Get FCM token
      String? token = await _messaging.getToken();
      print('📱 FCM Token for laboratory: $token');

      // Save subscription info and FCM token
      await _firestore.collection('lab_subscriptions').doc(laboratoryId).set({
        'subscribedAt': FieldValue.serverTimestamp(),
        'topic': labTopic,
        'isActive': true,
        'fcmToken': token,
        'userId': userId,
      });

      // Also update user document with FCM token
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error subscribing to laboratory topic: $e');
    }
  }

  /// Unsubscribe from laboratory topic
  Future<void> unsubscribeFromLabTopic(String laboratoryId) async {
    try {
      final labTopic = 'lab_$laboratoryId';
      await _messaging.unsubscribeFromTopic(labTopic);
      print('Unsubscribed from laboratory topic: $labTopic');

      // Update Firestore
      await _firestore.collection('lab_subscriptions').doc(laboratoryId).update(
        {'unsubscribedAt': FieldValue.serverTimestamp(), 'isActive': false},
      );
    } catch (e) {
      print('Error unsubscribing from laboratory topic: $e');
    }
  }

  /// Handle foreground notifications
  void handleForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 Got a message whilst in the foreground!');
      print('📊 Message data: ${message.data}');

      if (message.notification != null) {
        print('📬 Message notification: ${message.notification!.title}');

        // Show local notification
        await _showLocalNotification(message);
      }
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // Determine channel based on notification type
    String channelId = 'high_importance_channel';
    if (data['type'] == 'new_medicine_request') {
      channelId = 'medicine_requests';
    } else if (data['type'] == 'new_booking') {
      channelId = 'clinic_bookings';
    } else if (data['type'] == 'new_lab_booking') {
      channelId = 'lab_bookings';
    }

    // Ensure full content is visible in expanded notifications.
    final fullBody = (notification.body ?? '').trim();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'clinic_bookings'
          ? 'Clinic Bookings'
          : channelId == 'medicine_requests'
          ? 'Medicine Requests'
          : channelId == 'lab_bookings'
          ? 'Laboratory Bookings'
          : 'High Importance Notifications',
      channelDescription: 'Important app notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        fullBody,
        contentTitle: notification.title,
        summaryText: data['type'] == 'new_booking'
            ? 'تفاصيل الحجز'
            : data['type'] == 'booking_added_by_secretary'
            ? 'إضافة حجز بواسطة السكرتيرة'
            : data['type'] == 'booking_deleted'
            ? 'إلغاء حجز بواسطة السكرتيرة'
            : null,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(data),
    );

    print('✅ Local notification shown');
  }

  /// Handle notification taps
  void handleNotificationTaps() {
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationAction(message.data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationAction(message.data);

      // Navigate to medicine requests screen or bookings screen based on type
      final type = message.data['type'];
      if (type == 'new_booking') {
        // Navigate to bookings management
        print('Navigate to bookings management');
      } else if (type == 'new_medicine_request') {
        // Navigate to medicine requests
        print('Navigate to medicine requests');
      }
    });
  }

  /// Send notification to specific user by userId
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get user's FCM token from Firestore
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        print('❌ No FCM token for user: $userId');
        return;
      }

      // Note: Direct FCM sending requires Firebase Admin SDK or Cloud Functions
      // For now, we'll store the notification in Firestore for the user to read
      // In production, you should use Cloud Functions to send FCM messages

      await firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'fcmToken': fcmToken,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': data?['type'] ?? 'general',
      });

      print('✅ Notification queued for user: $userId');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
    }
  }

  /// Send notification to all users subscribed to a topic
  static Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Note: Direct topic messaging requires Firebase Admin SDK or Cloud Functions
      // For now, we'll store the notification for processing
      // In production, use Cloud Functions to send to topics

      await firestore.collection('topic_notifications').add({
        'topic': topic,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
        'type': data?['type'] ?? 'general',
      });

      print('✅ Notification queued for topic: $topic');
    } catch (e) {
      print('❌ Error sending notification to topic: $e');
    }
  }
}

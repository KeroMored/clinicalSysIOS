import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Topic name for all pharmacies
  static const String pharmacyTopic = 'pharmacy_requests';

  /// Initialize notifications and request permissions
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(medicineChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(bookingsChannel);

    print('✅ Notification channels created');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // You can navigate to specific screens here based on payload
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
      await _firestore.collection('lab_subscriptions').doc(laboratoryId).update({
        'unsubscribedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
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
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'clinic_bookings' ? 'Clinic Bookings' : 
      channelId == 'medicine_requests' ? 'Medicine Requests' : 
      'High Importance Notifications',
      channelDescription: notification.body,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
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
      payload: data['type'],
    );

    print('✅ Local notification shown');
  }

  /// Handle notification taps
  void handleNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
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

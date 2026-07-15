import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Test app to diagnose iOS notification issues
/// Run: flutter run -t lib/test_ios_notification.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TestApp());
}

class TestApp extends StatefulWidget {
  const TestApp({super.key});

  @override
  State<TestApp> createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  String _fcmToken = 'Getting token...';
  String _permissionStatus = 'Checking...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print('🔔 $message');
  }

  Future<void> _initializeNotifications() async {
    _addLog('Starting initialization...');

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _addLog('Local notifications initialized');

    // Request permission
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      setState(() {
        _permissionStatus = settings.authorizationStatus.toString();
      });
      
      _addLog('Permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _addLog('✅ Permission granted');
      } else {
        _addLog('❌ Permission denied');
        return;
      }
    } catch (e) {
      _addLog('❌ Permission error: $e');
      return;
    }

    // Get FCM token
    try {
      String? token = await _messaging.getToken();
      setState(() {
        _fcmToken = token ?? 'NULL TOKEN!';
      });
      
      if (token != null && token.isNotEmpty) {
        _addLog('✅ FCM Token: ${token.substring(0, 20)}...');
      } else {
        _addLog('❌ FCM Token is NULL - APNs not working!');
        return;
      }
    } catch (e) {
      _addLog('❌ Token error: $e');
      setState(() {
        _fcmToken = 'Error: $e';
      });
      return;
    }

    // Subscribe to test topic
    try {
      await _messaging.subscribeToTopic('all_users');
      _addLog('✅ Subscribed to topic: all_users');
    } catch (e) {
      _addLog('❌ Subscribe error: $e');
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addLog('📩 Foreground message received!');
      _addLog('Title: ${message.notification?.title}');
      _addLog('Body: ${message.notification?.body}');
      
      // Show local notification
      _showLocalNotification(message);
    });

    _addLog('🎉 Setup complete!');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Test',
      message.notification?.body ?? 'Message',
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('iOS Notification Test'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: _fcmToken.contains('NULL') || _fcmToken.contains('Error')
                    ? Colors.red[100]
                    : Colors.green[100],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FCM Token Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _fcmToken,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_permissionStatus),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Logs:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _initializeNotifications,
                  child: const Text('Retry Initialization'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Next Steps:\n'
                '1. Check if FCM Token is shown above\n'
                '2. Send test notification from Firebase Console\n'
                '   → Topic: all_users\n'
                '3. Notification should appear here',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

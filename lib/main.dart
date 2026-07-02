import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_app_check/firebase_app_check.dart'; // Disabled temporarily
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/security/security_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';
import 'features/pharmacy/data/repositories/pharmacy_repository.dart';
import 'features/pharmacy/presentation/cubit/pharmacy_cubit.dart';
import 'features/pharmacy/presentation/screens/pharmacy_details_screen.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/admin/presentation/cubit/admin_cubit.dart';
import 'features/admin/presentation/screens/add_pharmacy_screen.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/radiology/data/repositories/radiology_repository.dart';
import 'features/radiology/presentation/cubit/radiology_cubit.dart';
import 'features/delivery/data/repositories/delivery_repository.dart';
import 'features/delivery/presentation/cubit/delivery_cubit.dart';
import 'features/rehabilitation/data/repositories/rehabilitation_repository.dart';
import 'features/rehabilitation/presentation/cubit/rehabilitation_cubit.dart';
import 'features/gym/data/repositories/gym_repository.dart';
import 'features/gym/presentation/cubit/gym_cubit.dart';
import 'features/clinic/presentation/widgets/doctor_of_day_notification.dart';
import 'features/home/services/daily_health_tip_notification_service.dart';
import 'features/clinic/data/repositories/patient_repository.dart';
import 'features/clinic/presentation/cubit/patient_cubit.dart';
import 'features/medicine_reminders/data/repositories/medicine_repository.dart';
import 'features/medicine_reminders/presentation/cubit/medicine_cubit.dart';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase only if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print('Background message: ${message.messageId}');
}

// 🔥 Warm up Firestore connection in background
// This pre-establishes the connection before user needs it for login
void _warmUpFirestore() {
  // Intentionally disabled to minimize startup reads.
}

bool _fallbackShown = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  runZonedGuarded(() async {
    await _startApp();
  }, (error, stack) {
    _runFallbackApp();
    print('❌ Startup crash: $error');
  });
}

Future<void> _startApp() async {
  // Initialize locale for calendar
  await initializeDateFormatting('ar', null);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase App Check temporarily disabled
  // TODO: Re-enable after fixing configuration
  // try {
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     await FirebaseAppCheck.instance.activate(
  //       androidProvider: kDebugMode
  //           ? AndroidProvider.debug
  //           : AndroidProvider.playIntegrity,
  //       appleProvider: kDebugMode
  //           ? AppleProvider.debug
  //           : AppleProvider.appAttestWithDeviceCheckFallback,
  //     );
  //   }
  // } catch (e) {
  //   print('⚠️ App Check activation skipped: $e');
  // }

  // 🚀 Enable Firestore offline persistence and warm up connection
  // This makes the first login much faster
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  // Keep startup scroll smooth: run heavy background tasks in phases.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_startDeferredAppInitialization());
  });
}

void _runFallbackApp() {
  if (_fallbackShown) return;
  _fallbackShown = true;
  runApp(const _StartupErrorApp());
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFF3F8FB),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'حدث خطأ أثناء تشغيل التطبيق. برجاء إعادة المحاولة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _startDeferredAppInitialization() async {
  // Allow UI to settle first.
  await Future<void>.delayed(const Duration(seconds: 2));

  // Firestore warm-up can be expensive on some devices, so run it after first interaction.
  _warmUpFirestore();

  // Core messaging setup (needed for push delivery and local foreground handling).
  await _initializeCoreNotificationServices();

  // Low-priority services should never compete with first user interaction.
  unawaited(_initializeLowPriorityServices());
}

Future<void> _initializeCoreNotificationServices() async {
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    notificationService.handleForegroundNotifications();
    notificationService.handleNotificationTaps();
  } catch (e) {
    print('❌ Notification initialization error: $e');
  }
}

Future<void> _initializeLowPriorityServices() async {
  await Future<void>.delayed(const Duration(seconds: 8));

  // Security checks are intentionally skipped in debug to avoid startup stutter.
  try {
    if (!kDebugMode) {
      print('🔐 Initializing Security Manager...');
      final securityManager = SecurityManager();
      await securityManager.initialize();
    }
  } catch (e) {
    print('❌ Security initialization error: $e');
  }

  // Awesome notifications are low-priority at app startup.
  try {
    await DoctorOfTheDayNotification.initialize();
    await DoctorOfTheDayNotification.scheduleDailyNotification();

    await DailyHealthTipNotificationService.initialize();
    await DailyHealthTipNotificationService.scheduleDailyTipsAtMidnight();

    // Medicine notification service initializes lazily when scheduling reminders.
    print('✅ Background services initialized successfully');
  } catch (e) {
    print('❌ Error initializing Awesome Notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => PharmacyCubit(PharmacyRepository())),
        BlocProvider(create: (context) => AdminCubit(AdminRepository())),
        BlocProvider(
          create: (context) => AuthCubit(AuthRepository())..checkAuthState(),
        ),
        BlocProvider(
          create: (context) => RadiologyCubit(RadiologyRepository()),
        ),
        BlocProvider(create: (context) => DeliveryCubit(DeliveryRepository())),
        BlocProvider(
          create: (context) => RehabilitationCubit(RehabilitationRepository()),
        ),
        BlocProvider(create: (context) => GymCubit(GymRepository())),
        BlocProvider(create: (context) => PatientCubit(PatientRepository())),
        BlocProvider(create: (context) => MedicineCubit(MedicineRepository())),
      ],
      child: MaterialApp(
        title: "ملوي كيور - MallawyC are",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(),
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          // تثبيت حجم الخط وعدم تأثره بإعدادات النظام
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0, // تثبيت حجم الخط
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
        home: const AuthWrapper(),
        onGenerateRoute: (settings) {
          if (settings.name == '/pharmacy-details') {
            final pharmacyId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<PharmacyCubit>(),
                child: PharmacyDetailsScreen(pharmacyId: pharmacyId),
              ),
            );
          } else if (settings.name == '/add_pharmacy') {
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<AdminCubit>(),
                child: const AddPharmacyScreen(),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}

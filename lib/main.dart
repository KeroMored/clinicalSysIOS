import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/security/security_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
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

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

// 🔥 Warm up Firestore connection in background
// This pre-establishes the connection before user needs it for login
void _warmUpFirestore() {
  // Fire and forget - don't await
  // This makes a simple query to establish connection
  FirebaseFirestore.instance
      .collection('app_config')
      .doc('version')
      .get()
      .then((_) => print('✅ Firestore connection warmed up'))
      .catchError((e) => print('Firestore warm-up: $e'));
  
  // 🔥 Pre-warm commonly accessed collections in parallel
  // This speeds up first load of each screen
  final collections = ['radiology_centers', 'gyms', 'pharmacies', 'clinics'];
  for (final collection in collections) {
    FirebaseFirestore.instance
        .collection(collection)
        .where('isApproved', isEqualTo: true)
        .limit(1)
        .get()
        .then((_) => print('✅ $collection warmed up'))
        .catchError((e) => print('$collection warm-up: $e'));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 🚀 Enable Firestore offline persistence and warm up connection
  // This makes the first login much faster
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // 🔥 Warm up Firestore connection in background (don't wait)
  // This pre-establishes the connection before user needs it
  _warmUpFirestore();
  
  // Initialize Security Manager 🔐
  print('🔐 Initializing Security Manager...');
  final securityManager = SecurityManager();
  await securityManager.initialize();
  
  // Perform initial security check
  final securityCheck = await securityManager.performSecurityCheck();
  if (!securityCheck.isSecure) {
    print('⚠️ Security warnings detected:');
    for (final warning in securityCheck.warnings) {
      print('  - $warning');
    }
  }
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Initialize Doctor of the Day notifications
  try {
    await DoctorOfTheDayNotification.initialize();
    await DoctorOfTheDayNotification.scheduleDailyNotification();
    print('✅ Awesome Notifications initialized successfully');
  } catch (e) {
    print('❌ Error initializing Awesome Notifications: $e');
  }
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Handle foreground and notification taps
  notificationService.handleForegroundNotifications();
  notificationService.handleNotificationTaps();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PharmacyCubit(PharmacyRepository()),
        ),
        BlocProvider(
          create: (context) => AdminCubit(AdminRepository()),
        ),
        BlocProvider(
          create: (context) => AuthCubit(AuthRepository())..checkAuthState(),
        ),
        BlocProvider(
          create: (context) => RadiologyCubit(RadiologyRepository()),
        ),
        BlocProvider(
          create: (context) => DeliveryCubit(DeliveryRepository()),
        ),
        BlocProvider(
          create: (context) => RehabilitationCubit(RehabilitationRepository()),
        ),
        BlocProvider(
          create: (context) => GymCubit(GymRepository()),
        ),
      ],
      child: MaterialApp(
        title: "Mallawy Health Care",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme(),
        locale: const Locale('ar', 'EG'),
        supportedLocales: const [
          Locale('ar', 'EG'),
        ],
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
        home: const HomeScreen(),
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

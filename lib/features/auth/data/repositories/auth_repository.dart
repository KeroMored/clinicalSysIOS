import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/services/notification_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Let Google Sign-In read configuration automatically from GoogleService-Info.plist
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Cache for user model to avoid repeated Firestore reads
  UserModel? _cachedUser;
  String? _cachedUserId;

  // قائمة الأدمن (إيميلات محددة مسبقاً)
  final List<String> _adminEmails = [
    'admin@clinicalsystem.com',
    // أضف إيميلات الأدمن هنا
  ];

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// 🧹 تنظيف الاشتراكات القديمة عند تسجيل الدخول
  /// إذا تم تغيير دور المستخدم من pharmacy إلى user، يجب إلغاء الاشتراك من topics
  Future<void> _cleanupOldSubscriptions(UserModel user, String userId) async {
    try {
      // إذا كان المستخدم 'user' عادي، يجب إلغاء الاشتراك من أي pharmacy topics
      if (user.role == 'user') {
        // التحقق من وجود pharmacy_subscription
        final pharmacySubDoc = await _firestore
            .collection('pharmacy_subscriptions')
            .doc(userId)
            .get();

        if (pharmacySubDoc.exists) {
          print('🧹 إلغاء اشتراك المستخدم من pharmacy_requests topic');
          await _notificationService.unsubscribeFromPharmacyTopic(userId);
          // حذف subscription document
          await _firestore
              .collection('pharmacy_subscriptions')
              .doc(userId)
              .delete();
          print('✅ تم إلغاء اشتراك pharmacy بنجاح');
        }
      }
    } catch (e) {
      print('⚠️ خطأ في تنظيف الاشتراكات القديمة: $e');
      // لا نرمي الخطأ لأن هذا ليس حرجاً - المستخدم يمكنه تسجيل الدخول بدون تنظيف
    }
  }

  String _displayNameFromEmail(String email) {
    var userName = email.split('@')[0];
    userName = userName.replaceAll('.', ' ').replaceAll('_', ' ');
    return userName
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _displayNameFromAppleCredential(
    AuthorizationCredentialAppleID credential,
  ) {
    final parts = <String>[
      if ((credential.givenName ?? '').trim().isNotEmpty)
        credential.givenName!.trim(),
      if ((credential.familyName ?? '').trim().isNotEmpty)
        credential.familyName!.trim(),
    ];
    return parts.join(' ').trim();
  }

  Future<UserModel> _upsertSignedInUser(
    User firebaseUser, {
    String? displayNameOverride,
    String? photoUrlOverride,
    String? emailOverride,
  }) async {
    try {
      print('📝 [User Creation] Fetching user document for ${firebaseUser.uid}');
      
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('انتهت مهلة الاتصال بقاعدة البيانات'),
          );

      final email = (emailOverride ?? firebaseUser.email ?? '').trim();
      final normalizedEmail = email.isEmpty
          ? 'apple_${firebaseUser.uid}@noemail.local'
          : email;

      String userName = (displayNameOverride ?? firebaseUser.displayName ?? '')
          .trim();
      if (userName.isEmpty) {
        userName = _displayNameFromEmail(normalizedEmail);
      }

      if (userDoc.exists) {
        print('📝 [User Creation] User exists, loading data...');
        final user = UserModel.fromJson(userDoc.data()!);

        await _cleanupOldSubscriptions(user, firebaseUser.uid);
        _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

        if (user.role == 'pharmacy') {
          _notificationService.subscribeToPharmacyTopic(firebaseUser.uid);
        }

        print('✅ [User Creation] Existing user loaded successfully');
        return user;
      }

      print('📝 [User Creation] Creating new user...');
      
      final role = await _determineUserRole(normalizedEmail);

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: normalizedEmail,
        displayName: userName,
        photoUrl: photoUrlOverride ?? firebaseUser.photoURL ?? '',
        role: role,
        pharmacyId: null,
      );

      print('📝 [User Creation] Writing user to Firestore...');
      
      // CRITICAL FIX: Add await to ensure Firestore write completes
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toJson())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('انتهت مهلة حفظ بيانات المستخدم'),
          );

      print('✅ [User Creation] User created in Firestore successfully');

      // Subscribe to notifications (fire and forget)
      _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

      if (role == 'pharmacy') {
        _setupPharmacyUser(firebaseUser.uid, normalizedEmail);
      }

      print('✅ [User Creation] Complete! Returning user model');
      return newUser;
    } on TimeoutException catch (e) {
      print('❌ [User Creation] Timeout: $e');
      throw Exception('انتهت مهلة الاتصال بقاعدة البيانات، يرجى المحاولة مرة أخرى');
    } on FirebaseException catch (e) {
      print('❌ [User Creation] Firebase error: ${e.code} - ${e.message}');
      
      if (e.code == 'permission-denied') {
        throw Exception('لا تملك صلاحية الوصول، يرجى التواصل مع الدعم');
      }
      
      if (e.code == 'unavailable') {
        throw Exception('قاعدة البيانات غير متاحة حالياً، يرجى المحاولة لاحقاً');
      }
      
      throw Exception('خطأ في حفظ بيانات المستخدم: ${e.message ?? e.code}');
    } catch (e) {
      print('❌ [User Creation] Unexpected error: $e');
      throw Exception('حدث خطأ أثناء إنشاء حساب المستخدم: ${e.toString()}');
    }
  }

  // Sign in with Google - ULTRA FAST VERSION with Enhanced Error Handling
  Future<UserModel?> signInWithGoogle() async {
    try {
      print('🔐 [Google Sign-In] Starting sign-in flow...');
      print('🔐 [Google Sign-In] Bundle ID: com.mored.mallawycare');
      print('🔐 [Google Sign-In] Expected Client ID from GoogleService-Info.plist');
      
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().catchError((error) {
        print('❌ [Google Sign-In] signIn() error TYPE: ${error.runtimeType}');
        print('❌ [Google Sign-In] signIn() error DETAILS: $error');
        throw Exception('فشل تسجيل الدخول بواسطة Google: ${error.toString()}');
      });

      if (googleUser == null) {
        print('🔐 [Google Sign-In] User cancelled sign-in');
        return null;
      }

      print('🔐 [Google Sign-In] Got Google account: ${googleUser.email}');

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication.catchError((error) {
        print('❌ [Google Sign-In] getAuthentication() error: $error');
        throw Exception('فشل الحصول على بيانات التفويض من Google');
      });

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print('❌ [Google Sign-In] Missing authentication tokens');
        throw Exception('فشل الحصول على بيانات التفويض من Google');
      }

      print('🔐 [Google Sign-In] Got authentication tokens');

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 [Google Sign-In] Signing in to Firebase...');

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى',
            ),
          );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('❌ [Google Sign-In] Firebase user is null after sign-in');
        throw Exception('فشل تسجيل الدخول مع Firebase');
      }

      print('🔐 [Google Sign-In] Firebase auth successful for ${firebaseUser.uid}');
      print('🔐 [Google Sign-In] Creating/Updating user document...');

      return _upsertSignedInUser(
        firebaseUser,
        displayNameOverride: googleUser.displayName,
      );
    } on TimeoutException catch (e) {
      print('❌ [Google Sign-In] Timeout: $e');
      throw Exception('انتهت مهلة الاتصال، يرجى التحقق من اتصال الإنترنت');
    } on FirebaseAuthException catch (e) {
      print('❌ [Google Sign-In] Firebase auth exception: ${e.code} - ${e.message}');
      
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'هذا البريد الإلكتروني مسجل بطريقة دخول أخرى';
          break;
        case 'invalid-credential':
          errorMessage = 'بيانات الاعتماد غير صالحة، يرجى المحاولة مرة أخرى';
          break;
        case 'operation-not-allowed':
          errorMessage = 'تسجيل الدخول بواسطة Google غير مفعّل حالياً';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على هذا المستخدم';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'network-request-failed':
          errorMessage = 'خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى';
          break;
        default:
          errorMessage = 'فشل تسجيل الدخول: ${e.message ?? e.code}';
      }
      
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('❌ [Google Sign-In] Unexpected error: $e');
      print('❌ [Google Sign-In] Stack trace: $stackTrace');
      
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('sign_in_cancelled') || errorString.contains('canceled')) {
        print('🔐 [Google Sign-In] User cancelled');
        return null;
      }
      
      if (errorString.contains('network') || errorString.contains('connection')) {
        throw Exception('خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى');
      }
      
      if (errorString.contains('client') || errorString.contains('configuration')) {
        throw Exception('خطأ في إعدادات Google Sign-In، يرجى التواصل مع الدعم');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('حدث خطأ غير متوقع أثناء تسجيل الدخول');
    }
  }

  // Sign in with Apple - Enhanced with Better Error Handling
  Future<UserModel?> signInWithApple() async {
    try {
      print('🍎 [Apple Sign-In] Checking availability...');
      
      final isAvailable = await SignInWithApple.isAvailable().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      
      if (!isAvailable) {
        print('🍎 [Apple Sign-In] Not available on this device');
        throw Exception('تسجيل الدخول بواسطة Apple غير متاح على هذا الجهاز');
      }

      print('🍎 [Apple Sign-In] Generating nonce...');
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      print('🍎 [Apple Sign-In] Requesting Apple ID credential...');
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException(
          'انتهت مهلة الاتصال مع Apple',
        ),
      );

      print('🍎 [Apple Sign-In] Got credential, extracting identity token...');
      print('🍎 [Apple Sign-In] User ID: ${appleCredential.userIdentifier}');
      print('🍎 [Apple Sign-In] Email: ${appleCredential.email ?? "hidden"}');
      
      final identityToken = appleCredential.identityToken;
      
      if (identityToken == null || identityToken.isEmpty) {
        print('❌ [Apple Sign-In] Identity token is null or empty');
        throw Exception('فشل الحصول على بيانات التفويض من Apple');
      }

      print('🍎 [Apple Sign-In] Identity token length: ${identityToken.length}');
      print('🍎 [Apple Sign-In] Creating OAuth credential...');
      
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );

      print('🍎 [Apple Sign-In] Signing in to Firebase...');
      print('🍎 [Apple Sign-In] Using nonce: ${rawNonce.substring(0, 8)}...');
      
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(oauthCredential)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'انتهت مهلة الاتصال مع Firebase',
            ),
          );

      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        print('❌ [Apple Sign-In] Firebase user is null after sign-in');
        throw Exception('فشل تسجيل الدخول مع Firebase');
      }

      print('🍎 [Apple Sign-In] Firebase auth successful for ${firebaseUser.uid}');

      final displayNameOverride = _displayNameFromAppleCredential(
        appleCredential,
      );

      print('🍎 [Apple Sign-In] Creating/Updating user document...');
      
      return _upsertSignedInUser(
        firebaseUser,
        displayNameOverride: displayNameOverride.isEmpty
            ? null
            : displayNameOverride,
        emailOverride: appleCredential.email,
      );
    } on TimeoutException catch (e) {
      print('❌ [Apple Sign-In] Timeout: $e');
      throw Exception('انتهت مهلة الاتصال، يرجى المحاولة مرة أخرى');
    } on SignInWithAppleAuthorizationException catch (e) {
      print('🍎 [Apple Sign-In] Authorization exception: ${e.code}');
      
      if (e.code == AuthorizationErrorCode.canceled) {
        print('🍎 [Apple Sign-In] User cancelled');
        return null;
      }
      
      if (e.code == AuthorizationErrorCode.failed) {
        throw Exception('فشل تسجيل الدخول بواسطة Apple، يرجى المحاولة مرة أخرى');
      }
      
      if (e.code == AuthorizationErrorCode.invalidResponse) {
        throw Exception('استجابة غير صالحة من Apple، يرجى المحاولة مرة أخرى');
      }
      
      if (e.code == AuthorizationErrorCode.notHandled) {
        throw Exception('تعذر معالجة الطلب، يرجى المحاولة مرة أخرى');
      }
      
      if (e.code == AuthorizationErrorCode.unknown) {
        throw Exception('حدث خطأ غير معروف في تسجيل الدخول بواسطة Apple');
      }
      
      throw Exception('تعذر تسجيل الدخول بواسطة Apple: ${e.code}');
    } on FirebaseAuthException catch (e) {
      print('❌ [Apple Sign-In] Firebase auth exception: ${e.code} - ${e.message}');
      print('❌ [Apple Sign-In] Error details: ${e.toString()}');
      
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'هذا البريد الإلكتروني مسجل بطريقة دخول أخرى';
          break;
        case 'invalid-credential':
          errorMessage = 'بيانات الاعتماد غير صالحة. يرجى التحقق من:\n'
              '1. Firebase Console - Apple Sign-In settings\n'
              '2. Service ID: com.mored.mallawycare.signin\n'
              '3. Team ID: 84M47YB8XR\n'
              '4. Private Key (.p8) صحيح ومتطابق مع Key ID';
          break;
        case 'operation-not-allowed':
          errorMessage = 'تسجيل الدخول بواسطة Apple غير مفعّل حالياً';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'user-not-found':
          errorMessage = 'لم يتم العثور على هذا المستخدم';
          break;
        case 'network-request-failed':
          errorMessage = 'خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى';
          break;
        default:
          errorMessage = 'فشل تسجيل الدخول: ${e.message ?? e.code}';
      }
      
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      print('❌ [Apple Sign-In] Unexpected error: $e');
      print('❌ [Apple Sign-In] Stack trace: $stackTrace');
      
      if (e.toString().contains('network')) {
        throw Exception('خطأ في الاتصال بالإنترنت، يرجى المحاولة مرة أخرى');
      }
      
      if (e is Exception) {
        rethrow;
      }
      
      throw Exception('حدث خطأ غير متوقع أثناء تسجيل الدخول: ${e.toString()}');
    }
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // Background pharmacy setup (fire and forget)
  Future<void> _setupPharmacyUser(String uid, String email) async {
    try {
      // Subscribe to ALL users topic (general notifications)
      await _notificationService.subscribeToAllUsersTopic(uid);

      // Subscribe to pharmacy-specific notifications
      await _notificationService.subscribeToPharmacyTopic(uid);

      // Get pharmacy ID and update user
      final pharmacyId = await _getPharmacyIdByEmail(email);
      if (pharmacyId != null) {
        await _firestore.collection('users').doc(uid).update({
          'pharmacyId': pharmacyId,
        });
      }
    } catch (e) {
      print('Background pharmacy setup error: $e');
    }
  }

  // Determine user role based on email - OPTIMIZED with parallel queries
  Future<String> _determineUserRole(String email) async {
    // Check if admin first (instant check - no DB query)
    if (_adminEmails.contains(email.toLowerCase())) {
      return 'admin';
    }

    // For new users, run queries with timeout to avoid hanging
    // This makes first login much faster
    try {
      final results =
          await Future.wait([
            _firestore
                .collection('pharmacies')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
            _firestore
                .collection('clinics')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
            _firestore
                .collection('laboratories')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
            _firestore
                .collection('radiology_centers')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
            _firestore
                .collection('gyms')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
            _firestore
                .collection('rehabilitation_centers')
                .where('authEmails', arrayContains: email)
                .limit(1)
                .get(),
          ]).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // If timeout, throw to be caught below
              throw TimeoutException('Role check timeout');
            },
          );

      // Check in priority order
      // Pharmacy
      if (results[0].docs.isNotEmpty) {
        return 'pharmacy';
      }

      // Clinic
      if (results[1].docs.isNotEmpty) {
        return 'clinic_owner';
      }

      // Laboratory
      if (results[2].docs.isNotEmpty) {
        return 'laboratory';
      }

      // Radiology
      if (results[3].docs.isNotEmpty) {
        return 'radiology';
      }

      // Gym
      if (results[4].docs.isNotEmpty) {
        return 'gym';
      }

      // Rehabilitation
      if (results[5].docs.isNotEmpty) {
        return 'rehabilitation_center';
      }
    } on TimeoutException {
      print('⚠️ Role check timeout - defaulting to user');
    } catch (e) {
      print('Error checking user role: $e - defaulting to user');
    }

    // Default to regular user
    return 'user';
  }

  // Get pharmacy ID by owner email
  Future<String?> _getPharmacyIdByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('pharmacies')
          .where('authEmails', arrayContains: email)
          .where('status', isEqualTo: 'approved') // Only approved pharmacies
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error getting pharmacy ID: $e');
      return null;
    }
  }

  // Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    try {
      final user = currentUser;
      if (user == null) {
        _cachedUser = null;
        _cachedUserId = null;
        return null;
      }

      // Return cached user if same user and cache exists
      if (_cachedUserId == user.uid && _cachedUser != null) {
        return _cachedUser;
      }

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 8));

      if (docSnapshot.exists) {
        final userModel = UserModel.fromJson(docSnapshot.data()!);
        // Cache the user model
        _cachedUser = userModel;
        _cachedUserId = user.uid;
        return userModel;
      }
      // Fallback to Firebase Auth data if Firestore user document is missing.
      final fallbackUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
        role: 'user',
      );
      _cachedUser = fallbackUser;
      _cachedUserId = user.uid;
      return fallbackUser;
    } on TimeoutException {
      final user = currentUser;
      if (user == null) return null;

      // If Firestore is slow/offline, continue with cached Firebase Auth profile.
      final fallbackUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL ?? '',
        role: 'user',
      );
      _cachedUser = fallbackUser;
      _cachedUserId = user.uid;
      return fallbackUser;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Fallback model from FirebaseAuth profile when Firestore is unavailable.
  UserModel? getFallbackCurrentUserModel() {
    final user = currentUser;
    if (user == null) return null;

    final fallbackUser = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      role: 'user',
    );
    _cachedUser = fallbackUser;
    _cachedUserId = user.uid;
    return fallbackUser;
  }

  // Sign out - FAST VERSION
  Future<void> signOut() async {
    try {
      final user = currentUser;

      // Clear cache
      _cachedUser = null;
      _cachedUserId = null;

      // Sign out immediately (don't wait for notification cleanup)
      await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);

      // Cleanup notifications in background (fire and forget)
      if (user != null) {
        _cleanupUserNotifications(user.uid);
      }
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Background cleanup (fire and forget)
  Future<void> _cleanupUserNotifications(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        final userModel = UserModel.fromJson(docSnapshot.data()!);
        if (userModel.role == 'pharmacy') {
          await _notificationService.unsubscribeFromPharmacyTopic(uid);
        }
      }
    } catch (e) {
      print('Background notification cleanup error: $e');
    }
  }

  // Check if user is signed in
  bool isSignedIn() {
    return currentUser != null;
  }

  /// Ensure currently signed-in user is subscribed to general app notifications.
  Future<void> ensureAllUsersTopicSubscription() async {
    final user = currentUser;
    if (user == null) return;

    await _notificationService.subscribeToAllUsersTopic(user.uid);
  }
}

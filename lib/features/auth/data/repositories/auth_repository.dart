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
  static const String _iosGoogleClientId =
      '718616577077-gh7g5l90ouvpimafmqltnnqe5vcqbms9.apps.googleusercontent.com';
  final GoogleSignIn _googleSignIn = GoogleSignIn(clientId: _iosGoogleClientId);
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
    final userDoc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

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
      final user = UserModel.fromJson(userDoc.data()!);

      await _cleanupOldSubscriptions(user, firebaseUser.uid);
      _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

      if (user.role == 'pharmacy') {
        _notificationService.subscribeToPharmacyTopic(firebaseUser.uid);
      }

      return user;
    }

    final role = await _determineUserRole(normalizedEmail);

    final newUser = UserModel(
      uid: firebaseUser.uid,
      email: normalizedEmail,
      displayName: userName,
      photoUrl: photoUrlOverride ?? firebaseUser.photoURL ?? '',
      role: role,
      pharmacyId: null,
    );

    _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());
    _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

    if (role == 'pharmacy') {
      _setupPharmacyUser(firebaseUser.uid, normalizedEmail);
    }

    return newUser;
  }

  // Sign in with Google - ULTRA FAST VERSION
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }
      return _upsertSignedInUser(
        firebaseUser,
        displayNameOverride: googleUser.displayName,
      );
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign in with Apple
  Future<UserModel?> signInWithApple() async {
    try {
      print('🍎 [Apple Sign-In] Checking availability...');
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign-In غير متاح على هذا الجهاز حالياً');
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
      );

      print('🍎 [Apple Sign-In] Got credential, extracting identity token...');
      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Missing identity token from Apple');
      }

      print('🍎 [Apple Sign-In] Creating OAuth credential...');
      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: identityToken, rawNonce: rawNonce);

      print('🍎 [Apple Sign-In] Signing in to Firebase...');
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(oauthCredential);

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
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
    } on SignInWithAppleAuthorizationException catch (e) {
      print('🍎 [Apple Sign-In] Authorization exception: ${e.code}');
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw Exception('تعذر إكمال تسجيل الدخول بواسطة Apple: ${e.toString()}');
    } on FirebaseAuthException catch (e) {
      print('🍎 [Apple Sign-In] Firebase auth exception: ${e.code} - ${e.message}');
      throw Exception('فشل تسجيل الدخول بواسطة Apple: ${e.message ?? e.code}');
    } catch (e) {
      print('🍎 [Apple Sign-In] Unexpected error: $e');
      throw Exception('أخطأ في تسجيل الدخول بواسطة Apple: $e');
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

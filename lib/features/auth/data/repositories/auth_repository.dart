import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/services/notification_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Cache for user model to avoid repeated Firestore reads
  UserModel? _cachedUser;
  String? _cachedUserId;
  bool _isCachedFallbackUser = false;

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

      // Extract name from email (before @)
      String userName = firebaseUser.displayName ?? '';
      if (userName.isEmpty && firebaseUser.email != null) {
        // Get the part before @ and capitalize
        userName = firebaseUser.email!.split('@')[0];
        // Replace dots and underscores with spaces and capitalize
        userName = userName.replaceAll('.', ' ').replaceAll('_', ' ');
        // Capitalize first letter of each word
        userName = userName
            .split(' ')
            .map((word) {
              if (word.isEmpty) return word;
              return word[0].toUpperCase() + word.substring(1);
            })
            .join(' ');
      }

      // FAST PATH: Check if user exists in cache first
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        // User exists - return immediately from cache
        final user = UserModel.fromJson(userDoc.data()!);
        _cachedUser = user;
        _cachedUserId = firebaseUser.uid;
        _isCachedFallbackUser = false;

        // ✅ CLEANUP: إلغاء الاشتراك من topics إذا تم تغيير الدور
        // إذا كان المستخدم كان pharmacy/clinic لكن تم تغييره إلى user، يجب إلغاء الاشتراك
        await _cleanupOldSubscriptions(user, firebaseUser.uid);

        // Handle notifications in background (fire and forget)
        // ALL users subscribe to general topic
        _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

        if (user.role == 'pharmacy') {
          _notificationService.subscribeToPharmacyTopic(firebaseUser.uid);
        }

        return user;
      }

      // NEW USER: Determine role and create (only happens once per user)
      final role = await _determineUserRole(firebaseUser.email!);

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: userName,
        photoUrl: firebaseUser.photoURL ?? '',
        role: role,
        pharmacyId: null, // Will be set in background
      );

      _cachedUser = newUser;
      _cachedUserId = firebaseUser.uid;
      _isCachedFallbackUser = false;

      // Save user (fire and forget - don't wait)
      _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toJson());

      // Subscribe ALL new users to general topic
      _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

      // Handle pharmacy setup in background (fire and forget)
      if (role == 'pharmacy') {
        _setupPharmacyUser(firebaseUser.uid, firebaseUser.email!);
      }

      return newUser;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
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
      // Never lock on a fallback profile; always try Firestore to restore role/ids.
      if (_cachedUserId == user.uid && _cachedUser != null && !_isCachedFallbackUser) {
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
        _isCachedFallbackUser = false;
        return userModel;
      }
      // Fallback to Firebase Auth data if Firestore user document is missing.
      final fallbackUser = _buildFallbackUserModel(user);
      _cachedUser = fallbackUser;
      _cachedUserId = user.uid;
      _isCachedFallbackUser = true;
      return fallbackUser;
    } on TimeoutException {
      final user = currentUser;
      if (user == null) return null;

      // If Firestore is slow/offline, continue with cached Firebase Auth profile.
      final fallbackUser = _buildFallbackUserModel(user);
      _cachedUser = fallbackUser;
      _cachedUserId = user.uid;
      _isCachedFallbackUser = true;
      return fallbackUser;
    } catch (e) {
      final user = currentUser;
      if (user == null) {
        return null;
      }

      // Keep session alive even if Firestore read/parsing fails temporarily.
      final fallbackUser = _buildFallbackUserModel(user);
      _cachedUser = fallbackUser;
      _cachedUserId = user.uid;
      _isCachedFallbackUser = true;
      print('⚠️ Failed to load user profile from Firestore, using fallback: $e');
      return fallbackUser;
    }
  }

  // Fallback model from FirebaseAuth profile when Firestore is unavailable.
  UserModel? getFallbackCurrentUserModel() {
    final user = currentUser;
    if (user == null) return null;

    final fallbackUser = _buildFallbackUserModel(user);
    _cachedUser = fallbackUser;
    _cachedUserId = user.uid;
    _isCachedFallbackUser = true;
    return fallbackUser;
  }

  UserModel _buildFallbackUserModel(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      role: 'user',
    );
  }

  /// Wait briefly for Firebase Auth to restore persisted session after app launch.
  Future<User?> waitForSessionRestore({Duration timeout = const Duration(seconds: 3)}) async {
    if (currentUser != null) {
      return currentUser;
    }

    try {
      await authStateChanges.first.timeout(timeout);
    } catch (_) {
      // Ignore timeout/errors and return current best-known user.
    }

    return currentUser;
  }

  // Sign out - FAST VERSION
  Future<void> signOut() async {
    try {
      final user = currentUser;

      // Clear cache
      _cachedUser = null;
      _cachedUserId = null;
      _isCachedFallbackUser = false;

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

  // Sign in with Apple
  Future<UserModel?> signInWithApple() async {
    try {
      // Import sign_in_with_apple at the top if not already done
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // Build display name from Apple credentials if available
      String userName = firebaseUser.displayName ?? '';
      if (userName.isEmpty) {
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          userName = '${appleCredential.givenName} ${appleCredential.familyName}';
        } else if (firebaseUser.email != null) {
          userName = firebaseUser.email!.split('@')[0];
          userName = userName.replaceAll('.', ' ').replaceAll('_', ' ');
          userName = userName
              .split(' ')
              .map((word) {
                if (word.isEmpty) return word;
                return word[0].toUpperCase() + word.substring(1);
              })
              .join(' ');
        }
      }

      // Check if user exists
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final user = UserModel.fromJson(userDoc.data()!);
        _cachedUser = user;
        _cachedUserId = firebaseUser.uid;
        _isCachedFallbackUser = false;

        await _cleanupOldSubscriptions(user, firebaseUser.uid);
        _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

        if (user.role == 'pharmacy') {
          _notificationService.subscribeToPharmacyTopic(firebaseUser.uid);
        }

        return user;
      }

      // New user
      final role = await _determineUserRole(firebaseUser.email ?? '');

      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: userName,
        photoUrl: firebaseUser.photoURL ?? '',
        role: role,
        pharmacyId: null,
      );

      _cachedUser = newUser;
      _cachedUserId = firebaseUser.uid;
      _isCachedFallbackUser = false;

      _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toJson());

      _notificationService.subscribeToAllUsersTopic(firebaseUser.uid);

      if (role == 'pharmacy') {
        _setupPharmacyUser(firebaseUser.uid, firebaseUser.email ?? '');
      }

      return newUser;
    } catch (e) {
      throw Exception('Failed to sign in with Apple: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final userId = user.uid;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Unsubscribe from notifications
      await _cleanupUserNotifications(userId);

      // Delete Firebase Authentication account
      await user.delete();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear cache
      _cachedUser = null;
      _cachedUserId = null;
      _isCachedFallbackUser = false;
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}

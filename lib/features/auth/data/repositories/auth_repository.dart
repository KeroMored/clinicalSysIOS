import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/notification_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  // قائمة الأدمن (إيميلات محددة مسبقاً)
  final List<String> _adminEmails = [
    'admin@clinicalsystem.com',
    // أضف إيميلات الأدمن هنا
  ];

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with Google - ULTRA FAST VERSION
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

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
        userName = userName.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }

      // FAST PATH: Check if user exists in cache first
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        // User exists - return immediately from cache
        final user = UserModel.fromJson(userDoc.data()!);
        
        // Handle notifications in background (fire and forget)
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

      // Save user (fire and forget - don't wait)
      _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());
      
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
      // Subscribe to notifications
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
      final results = await Future.wait([
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
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
        // If timeout, throw to be caught below
        throw TimeoutException('Role check timeout');
      });

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
      if (user == null) return null;

      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        return UserModel.fromJson(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  // Sign out - FAST VERSION
  Future<void> signOut() async {
    try {
      final user = currentUser;
      
      // Sign out immediately (don't wait for notification cleanup)
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
      
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
}

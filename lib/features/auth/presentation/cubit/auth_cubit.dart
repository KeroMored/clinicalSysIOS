import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  // Check auth state on app start
  Future<void> checkAuthState() async {
    try {
      // Show loading briefly while checking Firebase Auth
      emit(AuthLoading());

      // Small delay to ensure Firebase Auth has restored session
      await Future.delayed(const Duration(milliseconds: 100));

      if (_authRepository.isSignedIn()) {
        final user = await _authRepository.getCurrentUserModel().timeout(
          const Duration(seconds: 12),
          onTimeout: () => _authRepository.getFallbackCurrentUserModel(),
        );
        if (user != null) {
          unawaited(_authRepository.ensureAllUsersTopicSubscription());
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated()); // Don't show error on initial check
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());

      final user = await _authRepository.signInWithGoogle();

      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('فشل تسجيل الدخول: ${e.toString()}'));
    }
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      print('🍎 [AuthCubit] Starting Apple Sign-In flow...');
      emit(AuthLoading());

      final user = await _authRepository.signInWithApple();
      
      print('🍎 [AuthCubit] Auth repository returned: ${user?.email}');

      if (user != null) {
        print('🍎 [AuthCubit] Apple Sign-In success! Emitting Authenticated state');
        emit(Authenticated(user));
      } else {
        print('🍎 [AuthCubit] Apple Sign-In returned null (user cancelled)');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('❌ [AuthCubit] Apple Sign-In error: $e');
      emit(AuthError('فشل تسجيل الدخول بواسطة Apple: ${e.toString()}'));
    }
  }

  // Sign out - FAST (no loading state)
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('فشل تسجيل الخروج: ${e.toString()}'));
    }
  }

  // Refresh user data (useful after pharmacy approval)
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUserModel();
      if (user != null) {
        unawaited(_authRepository.ensureAllUsersTopicSubscription());
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Get current user
  UserModel? get currentUser {
    if (state is Authenticated) {
      return (state as Authenticated).user;
    }
    return null;
  }
}

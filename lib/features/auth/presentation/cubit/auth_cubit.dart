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

  // Sign in with Google - Enhanced Error Handling
  Future<void> signInWithGoogle() async {
    try {
      print('🔐 [AuthCubit] Starting Google Sign-In flow...');
      emit(AuthLoading());

      final user = await _authRepository.signInWithGoogle().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('❌ [AuthCubit] Google Sign-In timeout');
          throw TimeoutException('انتهت مهلة تسجيل الدخول');
        },
      );

      if (user != null) {
        print('🔐 [AuthCubit] Google Sign-In success! Emitting Authenticated state');
        emit(Authenticated(user));
      } else {
        print('🔐 [AuthCubit] Google Sign-In returned null (user cancelled)');
        emit(Unauthenticated());
      }
    } on TimeoutException catch (e) {
      print('❌ [AuthCubit] Google Sign-In timeout: $e');
      emit(AuthError('انتهت مهلة تسجيل الدخول، يرجى المحاولة مرة أخرى'));
    } catch (e) {
      print('❌ [AuthCubit] Google Sign-In error: $e');
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(AuthError(errorMessage));
    }
  }

  // Sign in with Apple - Enhanced Error Handling
  Future<void> signInWithApple() async {
    try {
      print('🍎 [AuthCubit] Starting Apple Sign-In flow...');
      emit(AuthLoading());

      final user = await _authRepository.signInWithApple().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          print('❌ [AuthCubit] Apple Sign-In timeout');
          throw TimeoutException('انتهت مهلة تسجيل الدخول');
        },
      );
      
      if (user != null) {
        print('🍎 [AuthCubit] Apple Sign-In success! Emitting Authenticated state');
        emit(Authenticated(user));
      } else {
        print('🍎 [AuthCubit] Apple Sign-In returned null (user cancelled)');
        emit(Unauthenticated());
      }
    } on TimeoutException catch (e) {
      print('❌ [AuthCubit] Apple Sign-In timeout: $e');
      emit(AuthError('انتهت مهلة تسجيل الدخول، يرجى المحاولة مرة أخرى'));
    } catch (e) {
      print('❌ [AuthCubit] Apple Sign-In error: $e');
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(AuthError(errorMessage));
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

  // Delete account permanently
  Future<void> deleteAccount() async {
    try {
      print('🗑️ [AuthCubit] Starting account deletion...');
      emit(AuthLoading());

      await _authRepository.deleteAccount().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('انتهت مهلة حذف الحساب');
        },
      );

      print('✅ [AuthCubit] Account deleted successfully');
      emit(Unauthenticated());
    } on TimeoutException catch (e) {
      print('❌ [AuthCubit] Delete account timeout: $e');
      emit(AuthError('انتهت مهلة حذف الحساب، يرجى المحاولة مرة أخرى'));
    } catch (e) {
      print('❌ [AuthCubit] Delete account error: $e');
      
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      emit(AuthError(errorMessage));
      
      // Re-check auth state after error
      await checkAuthState();
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

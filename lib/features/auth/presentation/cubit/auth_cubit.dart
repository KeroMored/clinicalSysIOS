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

  // Check auth state on app start - FAST (no loading for initial check)
  Future<void> checkAuthState() async {
    try {
      if (_authRepository.isSignedIn()) {
        final user = await _authRepository.getCurrentUserModel();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
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

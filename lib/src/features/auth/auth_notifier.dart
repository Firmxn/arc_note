import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/dependency_injection.dart';
import '../../core/services/auth_persistence_service.dart';
import '../../core/utils/app_logger.dart';

// Auth state class
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'AuthState(isLoading: $isLoading, isAuthenticated: $isAuthenticated, user: $user, error: $error)';
  }
}

// AuthNotifier class
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AuthPersistenceService _persistenceService;

  AuthNotifier(this._authService, this._persistenceService) : super(const AuthState()) {
    _initializeAuth();
  }

  // Initialize auth state
  Future<void> _initializeAuth() async {
    try {
      state = state.copyWith(isLoading: true);

      // Initialize persistence service
      await _persistenceService.initialize();

      // Check for saved session first
      final hasValidSession = await _persistenceService.hasValidSession();

      if (hasValidSession) {
        // Try to restore session from Supabase
        final currentSession = _authService.currentSession;
        final currentUser = _authService.currentUser;

        if (currentSession != null && currentUser != null) {
          // Session is still valid
          await _persistenceService.updateLastActive();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: currentUser,
            error: null,
          );
          AppLogger.info('Session restored for user: ${currentUser.email}');
          return;
        } else {
          // Clear invalid saved session
          await _persistenceService.clearSession();
        }
      }

      // Listen to auth state changes
      _authService.authStateChanges.listen((authState) async {
        if (authState.session != null) {
          // Save session to persistence
          await _persistenceService.saveSession(
            authState.session!,
            authState.session!.user,
          );

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            user: authState.session!.user,
            error: null,
          );
          AppLogger.info('User authenticated: ${authState.session!.user.email}');
        } else {
          // Clear saved session
          await _persistenceService.clearSession();

          state = state.copyWith(
            isLoading: false,
            isAuthenticated: false,
            user: null,
            error: null,
          );
          AppLogger.info('User not authenticated');
        }
      });

      // Check current auth state immediately
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final currentSession = _authService.currentSession;
        if (currentSession != null) {
          await _persistenceService.saveSession(currentSession, currentUser);
        }

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: currentUser,
          error: null,
        );
        AppLogger.info('Current user authenticated: ${currentUser.email}');
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      AppLogger.error('Failed to initialize auth', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize authentication: ${e.toString()}',
      );
    }
  }

  // Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.success) {
        // State will be updated by auth state listener
        AppLogger.info('Sign in successful for: $email');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Sign in failed',
        );
      }
    } catch (e) {
      AppLogger.error('Sign in error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during sign in',
      );
    }
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.success) {
        // State will be updated by auth state listener
        AppLogger.info('Sign up successful for: $email');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Sign up failed',
        );
      }
    } catch (e) {
      AppLogger.error('Sign up error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during sign up',
      );
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.signInWithGoogle();

      if (result.success) {
        // State will be updated by auth state listener
        AppLogger.info('Google sign in successful');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Google sign in failed',
        );
      }
    } catch (e) {
      AppLogger.error('Google sign in error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during Google sign in',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true);

      final result = await _authService.signOut();

      if (result.success) {
        // State will be updated by auth state listener
        AppLogger.info('Sign out successful');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Sign out failed',
        );
      }
    } catch (e) {
      AppLogger.error('Sign out error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during sign out',
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.resetPassword(email);

      if (result.success) {
        state = state.copyWith(isLoading: false);
        AppLogger.info('Password reset email sent to: $email');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Password reset failed',
        );
      }
    } catch (e) {
      AppLogger.error('Password reset error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during password reset',
      );
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _authService.updatePassword(newPassword);

      if (result.success) {
        state = state.copyWith(isLoading: false);
        AppLogger.info('Password updated successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error ?? 'Password update failed',
        );
      }
    } catch (e) {
      AppLogger.error('Password update error', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during password update',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for AuthPersistenceService
final authPersistenceServiceProvider = Provider<AuthPersistenceService>((ref) {
  return AuthPersistenceService();
});

// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final persistenceService = ref.watch(authPersistenceServiceProvider);
  return AuthNotifier(authService, persistenceService);
});

// Provider for auth state
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});

// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});
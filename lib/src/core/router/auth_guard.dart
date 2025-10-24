import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_notifier.dart';

// Auth guard for protecting routes
class AuthGuard {
  static String redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = context.read(isAuthenticatedProvider);
    final isLoading = context.read(authNotifierProvider).isLoading;

    // If still loading, stay on current route
    if (isLoading) {
      return state.location;
    }

    // If not authenticated and not on auth routes, redirect to login
    if (!isAuthenticated && !_isAuthRoute(state.location)) {
      return '/login';
    }

    // If authenticated and on auth routes, redirect to home
    if (isAuthenticated && _isAuthRoute(state.location)) {
      return '/home';
    }

    // No redirect needed
    return state.location;
  }

  static bool _isAuthRoute(String location) {
    return location.startsWith('/login') ||
           location.startsWith('/signup') ||
           location.startsWith('/forgot-password') ||
           location.startsWith('/splash');
  }
}

// Stream-based redirect function for real-time auth changes
Future<String> authRedirect(BuildContext context, GoRouterState state) async {
  final authNotifier = context.read(authNotifierProvider.notifier);

  // Wait a moment for auth state to initialize
  await Future.delayed(const Duration(milliseconds: 100));

  return AuthGuard.redirect(context, state);
}

// Auth-aware navigation shell
class AuthAwareNavigationShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const AuthAwareNavigationShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Show loading overlay while auth state is being determined
    if (authState.isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...'),
              ],
            ),
          ),
        ),
      );
    }

    // If not authenticated and not on auth routes, show login screen
    if (!authState.isAuthenticated && !_isAuthRoute(currentRoute)) {
      return const LoginScreen();
    }

    // If authenticated and on auth routes, show home screen
    if (authState.isAuthenticated && _isAuthRoute(currentRoute)) {
      return const HomeScreen();
    }

    return child;
  }

  bool _isAuthRoute(String location) {
    return location.startsWith('/login') ||
           location.startsWith('/signup') ||
           location.startsWith('/forgot-password') ||
           location.startsWith('/splash');
  }
}

// Import necessary screens (will be available after implementing all screens)
import '../../features/auth/login_screen.dart';
import '../../features/notes/screens/home_screen.dart';
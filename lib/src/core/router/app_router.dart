import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/auth_guard.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/notes/screens/home_screen.dart';
import '../../features/notes/screens/note_detail_screen.dart';
import '../../features/auth/auth_notifier.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: authRedirect,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Protected Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const AuthAwareNavigationShell(
          currentRoute: '/home',
          child: HomeScreen(),
        ),
      ),

      GoRoute(
        path: '/note/:id',
        name: 'note_detail',
        builder: (context, state) {
          final String noteId = state.pathParameters['id']!;
          return AuthAwareNavigationShell(
            currentRoute: '/note/$noteId',
            child: NoteDetailScreen(noteId: noteId),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// Temporary placeholder widgets - will be implemented in future tasks
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Forgot Password Screen - Coming Soon'),
      ),
    );
  }
}
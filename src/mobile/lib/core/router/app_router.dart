import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/processing/presentation/processing_screen.dart';
import '../../features/viewer/presentation/viewer_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';

/// Global navigator key shared with DrawingNotifier
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state changes
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    // Refresh router when auth state changes
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isFirstTime = authState.isFirstTime;
      final path = state.matchedLocation;

      // Debug log
      debugPrint('Router redirect: path=$path, isAuthenticated=$isAuthenticated, isFirstTime=$isFirstTime');

      // If on splash, let it load
      if (path == '/splash') return null;

      // If authenticated, redirect to home from auth pages
      if (isAuthenticated && (path == '/login' || path == '/signup' || path == '/onboarding')) {
        return '/home';
      }

      // Protected routes that require authentication
      final protectedPrefixes = ['/home', '/camera', '/processing', '/viewer', '/admin'];

      // Check if path matches any protected route
      final isProtectedRoute = protectedPrefixes.any((prefix) => path.startsWith(prefix));

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && isProtectedRoute) {
        // First time: show onboarding
        if (isFirstTime) {
          return '/onboarding';
        }
        // Not first time: show login
        return '/login';
      }

      // If not authenticated on public routes
      if (!isAuthenticated) {
        // First time: show onboarding
        if (isFirstTime && path != '/onboarding') {
          return '/onboarding';
        }
        // Not first time: allow login or signup
        if (!isFirstTime && path != '/login' && path != '/signup') {
          return '/login';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/processing/:drawingId',
        name: 'processing',
        builder: (context, state) {
          final drawingId = state.pathParameters['drawingId']!;
          return ProcessingScreen(drawingId: drawingId);
        },
      ),
      GoRoute(
        path: '/viewer/:drawingId',
        name: 'viewer',
        builder: (context, state) {
          final drawingId = state.pathParameters['drawingId']!;
          return ViewerScreen(drawingId: drawingId);
        },
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});

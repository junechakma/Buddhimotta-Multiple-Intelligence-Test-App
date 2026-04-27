import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/terms_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/test/mi_test_screen.dart';
import '../services/guest_session.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static void refreshAuth() => _AuthChangeNotifier.refresh();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _AuthChangeNotifier(),
    redirect: (context, state) {
      final loggedIn =
          FirebaseAuth.instance.currentUser != null || GuestSession.isGuest;
      final loc = state.matchedLocation;
      final isPublic =
          loc == '/login' || loc == '/signup' || loc == '/terms';

      if (!loggedIn && !isPublic) return '/login';
      if (loggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login',     builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/signup',    builder: (context, _) => const SignupScreen()),
      GoRoute(path: '/terms',     builder: (context, _) => const TermsScreen()),
      GoRoute(path: '/home',      builder: (context, _) => const HomeScreen()),
      GoRoute(path: '/intro',     builder: (context, _) => const PlaceholderScreen(titleKey: 'what_is_mi')),
      GoRoute(path: '/test',      builder: (context, _) => const MiTestScreen()),
      GoRoute(path: '/scenarios', builder: (context, _) => const PlaceholderScreen(titleKey: 'real_life_test')),
      GoRoute(
        path: '/results',
        builder: (context, state) => ResultsScreen(
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(path: '/about',     builder: (context, _) => const PlaceholderScreen(titleKey: 'about_us')),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('পেজটি পাওয়া যায়নি: ${state.error}')),
    ),
  );
}

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    _instance = this;
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;
  static _AuthChangeNotifier? _instance;

  static void refresh() => _instance?.notifyListeners();

  @override
  void dispose() {
    _instance = null;
    _sub.cancel();
    super.dispose();
  }
}

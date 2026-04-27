import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/terms_screen.dart';
import '../screens/home/home_screen.dart';
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // More routes added as each screen is converted
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

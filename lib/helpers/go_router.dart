// router.dart
import 'package:bobadex/navigation.dart';
import 'package:bobadex/pages/auth_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/reset_password_page.dart';
import 'package:bobadex/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState extends ChangeNotifier {
  bool isLoading = true;
  bool isLoggedIn = false;

  AuthState() {
    _init();
    Supabase.instance.client.auth.onAuthStateChange.listen((e) {
      if (e.event == AuthChangeEvent.passwordRecovery) {
        notifyListeners();
      }
      _applySession(e.session);
    });
  }

  Future<void> _init() async {
    _applySession(Supabase.instance.client.auth.currentSession);
    isLoading = false;
    notifyListeners();
  }

  void _applySession(Session? s) {
    final logged = s?.user != null;
    if (logged != isLoggedIn) {
      isLoggedIn = logged;
      notifyListeners();
    }
  }
}

GoRouter buildRouter({ required AuthState auth, List<NavigatorObserver> observers = const [] }) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: observers,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          return uid == null ? '/auth' : '/home';
        },
      ),
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/auth',  builder: (_, __) => const AuthPage()),
      GoRoute(path: '/reset',  builder: (_, __) => const ResetPasswordPage()),
      GoRoute(
        path: '/home',
        builder: (context, __) {
          final uid = Supabase.instance.client.auth.currentUser?.id;
          if (uid == null) return const SplashPage(); // defensive
          return HomePage(userId: uid);
        },
      ),
    ],
    errorBuilder: (_, __) => const AuthPage(),
  );
}

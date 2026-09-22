import 'package:bobadex/config/feature_flags.dart';
import 'package:bobadex/helpers/branch_nav.dart';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/app_shell.dart';
import 'package:bobadex/pages/auth_page.dart';
import 'package:bobadex/pages/collection_page.dart';
import 'package:bobadex/pages/friends_hub_page.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/pages/splash_page.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthState extends ChangeNotifier {
  bool isLoading = true;
  bool isLoggedIn = false;

  AuthState() {
    _init();
    Supabase.instance.client.auth.onAuthStateChange.listen((e) {
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

final dexNavKey = GlobalKey<NavigatorState>(debugLabel: 'dex');
final collectNavKey = GlobalKey<NavigatorState>(debugLabel: 'collect');
final friendsNavKey = GlobalKey<NavigatorState>(debugLabel: 'friends');
final youNavKey = GlobalKey<NavigatorState>(debugLabel: 'you');

final dexNavNotifier = BranchNavNotifier();
final collectNavNotifier = BranchNavNotifier();
final friendsNavNotifier = BranchNavNotifier();
final youNavNotifier = BranchNavNotifier();

GoRouter buildRouter({
  required AuthState auth,
  List<NavigatorObserver> observers = const [],
}) {
  final branchNotifiers = <BranchNavNotifier>[
    dexNavNotifier,
    if (FeatureFlags.collection) collectNavNotifier,
    friendsNavNotifier,
    youNavNotifier,
  ];

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    observers: observers,
    refreshListenable: auth,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggingIn = loc == '/auth';
      final splashing = loc == '/splash';

      if (auth.isLoading) {
        return splashing ? null : '/splash';
      }
      if (!auth.isLoggedIn && !loggingIn && !splashing) return '/auth';
      if (auth.isLoggedIn && loggingIn) return '/dex';
      if (auth.isLoggedIn && (loc == '/' || loc == '/home')) return '/dex';
      if (!FeatureFlags.collection && loc.startsWith('/collect')) {
        return '/dex';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthPage()),
      GoRoute(path: '/home', redirect: (_, _) => '/dex'),
      GoRoute(path: '/', redirect: (_, _) => '/dex'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          branchNotifiers: branchNotifiers,
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: dexNavKey,
            observers: [dexNavNotifier],
            routes: [
              GoRoute(
                path: '/dex',
                builder: (context, state) {
                  final uid =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  return HomePage(userId: uid);
                },
              ),
            ],
          ),
          if (FeatureFlags.collection)
            StatefulShellBranch(
              navigatorKey: collectNavKey,
              observers: [collectNavNotifier],
              routes: [
                GoRoute(
                  path: '/collect',
                  builder: (_, _) => const CollectionPage(),
                ),
              ],
            ),
          StatefulShellBranch(
            navigatorKey: friendsNavKey,
            observers: [friendsNavNotifier],
            routes: [
              GoRoute(
                path: '/friends',
                builder: (_, _) => const FriendsHubPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: youNavKey,
            observers: [youNavNotifier],
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) {
                  final user = context.read<UserState>().current;
                  return AccountViewPage(
                    userId: user.id,
                    user: user,
                    inShell: true,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const AuthPage(),
  );
}

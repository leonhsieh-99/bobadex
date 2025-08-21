import 'dart:async';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/user_state.dart';
import 'state/drink_state.dart';
import 'state/user_stats_cache.dart';
import 'state/brand_state.dart';
import 'state/shop_state.dart';
import 'models/user.dart' as u;

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  Session? _lastHandledSession;
  String? _lastUserId;
  bool _routingLock = false;
  StreamSubscription? _achievmentSub;
  StreamSubscription<AuthState>? _authSub;
  late u.User user;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _achievmentSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _resetAllStates() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<UserState>().reset();
        context.read<DrinkState>().reset();
        context.read<ShopState>().reset();
        context.read<BrandState>().reset();
        context.read<FriendState>().reset();
        context.read<UserStatsCache>().clearCache();
        context.read<ShopMediaState>().reset();
        context.read<AchievementsState>().reset();
        context.read<FeedState>().reset();
      } catch (e) {
        debugPrint('Error resetting states: $e');
      }
    });
  }


  Future<void> _initializeSession() async {
    final auth = Supabase.instance.client.auth;

    navigatorKey.currentState?.pushNamedAndRemoveUntil('/splash', (_) => false);

    try {
      final currentSession = auth.currentSession;
      if (currentSession != null) {
        _routingLock = true;
        await _handleSignedIn(currentSession);
        _lastUserId = currentSession.user.id;
        _routingLock = false;
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (_) => false);
      } else {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);
      }
    } catch (e) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);
    }

    // Listen to auth state changes
    _authSub?.cancel();
    _authSub = auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
        navigatorKey.currentState?.pushReplacementNamed('/reset');
        return;
      }

      if (event == AuthChangeEvent.signedIn && session != null) {
        if (_routingLock) return;
        _routingLock = true;

        navigatorKey.currentState?.pushNamedAndRemoveUntil('/splash', (_) => false);
        try {
          await _handleSignedIn(session);
          _lastUserId = session.user.id;
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (_) => false);
        } catch (_) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);
        } finally {
          _routingLock = false;
        }
        return;
      }
      
      if (event == AuthChangeEvent.signedOut) {
        if (_routingLock) return;
        _routingLock = true;
        _resetAllStates();
        _achievmentSub?.cancel();
        _achievmentSub = null;
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);
        _routingLock = false;
        return;
      }

      if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        if (_lastUserId == session.user.id) return;
        try {
          await _handleSignedIn(session);
          _lastUserId = session.user.id;
        } catch (e) {
          debugPrint('Token refresh reload failed: $e');
        }
      }
    });
  }

  Future<void> _handleSignedIn(Session session) async {
    if (_lastHandledSession?.accessToken == session.accessToken) return;
    _lastHandledSession = session;
    _lastUserId = session.user.id;

    final userState = context.read<UserState>();
    final drinkState = context.read<DrinkState>();
    final shopState = context.read<ShopState>();
    final brandState = context.read<BrandState>();
    final friendState = context.read<FriendState>();
    final shopMediaState = context.read<ShopMediaState>();
    final achievementsState = context.read<AchievementsState>();
    final feedState = context.read<FeedState>();

    await userState.loadFromSupabase();

    final user = userState.user;
    if (user.id.isEmpty) {
      debugPrint('No valid user loaded — skipping rest');
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (_) => false);
      return;
    }
    this.user = user;

    await Future.wait([
      drinkState.loadFromSupabase(),
      brandState.loadFromSupabase(),
      shopState.loadFromSupabase(),
      friendState.loadFromSupabase(),
      shopMediaState.loadFromSupabase(),
      achievementsState.loadFromSupabase(),
    ]);

    final hasErrors = [
      drinkState.hasError,
      brandState.hasError,
      shopState.hasError,
      friendState.hasError,
      shopMediaState.hasError,
      achievementsState.hasError,
    ].any((e) => e);

    if (hasErrors) {
      debugPrint('Some providers failed to load. Showing partial data.');
      if(mounted) {
        notify(
          'Some data failed to load. Try refreshing.',
          SnackType.error,
        );
      }
    }

    if (_achievmentSub != null) {
      try {
        await _achievmentSub!.cancel();
      } catch (e) {
        debugPrint('Error canceling achievement listener: $e');
      }
      _achievmentSub = null;
    }
    _achievmentSub = achievementsState.unlockedAchievementsStream.listen((achievement) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        notifyAchievement(achievement.name);
        context.read<FeedState>().fetchFeed(refresh: true);
      });
    });
    
    try {
      await Future.wait([
        achievementsState.checkAndUnlockShopAchievement(shopState),
        achievementsState.checkAndUnlockDrinkAchievement(drinkState),
        achievementsState.checkAndUnlockFriendAchievement(friendState),
        achievementsState.checkAndUnlockNotesAchievement(drinkState),
        achievementsState.checkAndUnlockMaxDrinksShopAchievement(drinkState),
        achievementsState.checkAndUnlockMediaUploadAchievement(shopMediaState),
        achievementsState.checkAndUnlockBrandAchievement(shopState),
        achievementsState.checkAndUpdateAllAchievement(),
      ]);
      debugPrint('Loaded ${achievementsState.userAchievements.length} user achievements');
    } catch (e) {
      debugPrint('Error loading user achievements: $e');
    }

    try {
      await feedState.fetchFeed();
      debugPrint('Loaded ${feedState.feed.length} feed events');
    } catch (e) {
      debugPrint('Error loading feed state: $e');
    }
  }


  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

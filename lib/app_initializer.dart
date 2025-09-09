import 'dart:async';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/media_realtime_service.dart';
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
  final _mediaRT = MediaRealtimeService();
  late u.User user;

  @override
  void initState() {
    super.initState();
    initializeAuthFlow();
  }

  @override
  void dispose() {
    _achievmentSub?.cancel();
    _authSub?.cancel();
    _mediaRT.stop();
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

  Future<void> _go(String route) async {
    // Ensure navigator is ready before pushing
    while (navigatorKey.currentState == null) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    navigatorKey.currentState!.pushNamedAndRemoveUntil(route, (_) => false);
  }

  Future<void> initializeAuthFlow() async {
    final auth = Supabase.instance.client.auth;

    // Show splash once
    unawaited(_go('/splash'));

    // (Re)subscribe
    await _authSub?.cancel();
    _authSub = auth.onAuthStateChange.listen((data) async {
      final event   = data.event;
      final session = data.session;

      debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState!.pop();
        }
        await _go('/reset');
        return;
      }

      if (_routingLock) return;
      _routingLock = true;
      try {
        switch (event) {
          case AuthChangeEvent.initialSession:
            if (session != null) {
              unawaited(_go('/splash'));
              final ok = await _handleSignedIn(session);
              await _go(ok ? '/home' : '/auth');
            } else {
              await _go('/auth');
            }
            break;

          case AuthChangeEvent.signedIn:
            if (session != null) {
              unawaited(_go('/splash'));
              final ok = await _handleSignedIn(session);
              await _go(ok ? '/home' : '/auth');
            } else {
              await _go('/auth');
            }
            break;

          case AuthChangeEvent.signedOut:
            _resetAllStates();
            await _achievmentSub?.cancel();
            _achievmentSub = null;
            await _mediaRT.stop();
            await _go('/auth');
            break;

          case AuthChangeEvent.tokenRefreshed:
            if (session != null && _lastUserId != session.user.id) {
              try {
                // refresh data quietly; no nav here
                await _handleSignedIn(session);
                _lastUserId = session.user.id;
              } catch (e) {
                debugPrint('Token refresh reload failed: $e');
              }
            }
            break;

          default:
            break;
        }
      } catch (e, st) {
        debugPrint('Auth flow error: $e\n$st');
        await _go('/auth');
      } finally {
        _routingLock = false;
      }
    });
  }

  Future<bool> _handleSignedIn(Session session) async {
    if (_lastHandledSession?.accessToken == session.accessToken) return true;
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

    await userState.loadCurrent();

    final user = userState.current;
    if (user.id.isEmpty) {
      debugPrint('No valid user loaded — skipping rest');
      return false;
    }
    this.user = user;

    final drinkCount = await drinkState.fetchDrinkCount(user.id);
    final futures = [
      brandState.loadFromSupabase(),
      shopState.loadCurrentUser(force: true),
      shopState.loadDrinkCountsForCurrentUser(),
      friendState.loadFromSupabase(),
      shopMediaState.loadFromSupabase(),
      achievementsState.loadFromSupabase(),
    ];

    if (drinkCount < Constants.maxDrinkCountForFetchAll) {
      futures.add(drinkState.loadAllForUser(user.id));
    }

    await Future.wait(futures);

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
      try { await _achievmentSub!.cancel(); } catch (_) {}
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

    _mediaRT.start(
      onDeleteById: (deletedId) async {
        if (!mounted) return;
        try {
          context.read<ShopMediaState>().removeCache(deletedId);
          context.read<FeedState>().removeImageCache(deletedId);
        } catch (e) {
          debugPrint('onDeleteById prune error: $e');
        }
      },
      onOwnMediaDeleted: (_) {
        notify('One of your uploads was removed by moderators.', SnackType.error);
      },
    );


    return true;
  }


  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

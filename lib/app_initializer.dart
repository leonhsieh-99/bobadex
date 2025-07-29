import 'dart:async';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'state/user_state.dart';
import 'pages/splash_page.dart';
import 'state/drink_state.dart';
import 'state/user_stats_cache.dart';
import 'state/brand_state.dart';
import 'state/shop_state.dart';
import 'pages/auth_page.dart';
import 'models/user.dart' as u;
import 'pages/home_page.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isReady = false;
  Session? _session;
  StreamSubscription? _achievementListener;
  StreamSubscription? _uniLinksSub;
  late u.User user;

  String? _lastSessionId;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _achievementListener?.cancel();
    _uniLinksSub?.cancel();
    super.dispose();
  }

  void _initDeepLinks() {
    // For when the app is already running
    _uniLinksSub = linkStream.listen((String? link) {
      if (link != null) {
        _handleIncomingAuthLink(link);
      }
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });

    // For when the app is started from a deep link
    getInitialLink().then((String? link) {
      if (link != null) {
        _handleIncomingAuthLink(link);
      }
    });
  }

  void _handleIncomingAuthLink(String link) async {
    debugPrint('Received deep link: $link');
    Uri uri = Uri.parse(link);
    String fragment = uri.fragment;

    if (fragment.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.recoverSession(fragment);
        debugPrint('Session recovered from deep link!');
      } catch (e) {
        debugPrint('Failed to recover session from deep link: $e');
      }
    } else {
      debugPrint('Deep link did not contain auth tokens.');
    }
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
    final supabase = Supabase.instance.client.auth;

    // Listen to auth state changes
    supabase.onAuthStateChange.listen((data) {
      handleSession(data.session);
    });

    handleSession(supabase.currentSession);
  }

  void handleSession(Session? session) async {
    final currentSessionId = session?.accessToken ?? '';
    if (_lastSessionId == currentSessionId) {
      debugPrint('handleSession: Duplicate session event, skipping');
      return;
    }
    _lastSessionId = currentSessionId;
    
    if (session != null) {
      setState(() {
        _isReady = false;
        _session = session;
      });
      
      // Only read providers when we have a valid session
      final userState = context.read<UserState>();
      final drinkState = context.read<DrinkState>();
      final shopState = context.read<ShopState>();
      final brandState = context.read<BrandState>();
      final friendState = context.read<FriendState>();
      final shopMediaState = context.read<ShopMediaState>();
      final achievementsState = context.read<AchievementsState>();
      final feedState = context.read<FeedState>();

      try {
        await userState.loadFromSupabase();
        debugPrint('Loaded user state');
      } catch (e) {
        debugPrint('Error loading user state: $e');
      }

      final user = context.read<UserState>().user;
      if (user.id.isEmpty) {
        debugPrint('No valid user loaded — skipping rest');
        if (mounted) {
          setState(() {
            _session = null;
            _isReady = true;
          });
        }
        return;
      }
      this.user = user;

      try {
        await drinkState.loadFromSupabase();
        debugPrint('Loaded ${drinkState.all.length} drinks');
      } catch (e) {
        debugPrint('Error loading drinks: $e');
      }

      try {
        await brandState.loadFromSupabase();
        debugPrint('Loaded ${brandState.all.length} brands');
      } catch (e) {
        debugPrint('Error loading brands: $e');
      }

      try {
        await shopState.loadFromSupabase();
        debugPrint('Loaded ${shopState.all.length} shops');
      } catch (e) {
        debugPrint('Error loading shops: $e');
      }

      try {
        await friendState.loadFromSupabase();
        debugPrint('Loaded ${friendState.allFriendships.length} friendships');
      } catch (e) {
        debugPrint('Error loading friend state: $e');
      }

      try {
        await shopMediaState.loadFromSupabase();
        debugPrint('Loaded ${shopMediaState.all.length} shop medias');
      } catch (e) {
        debugPrint('Error loading shop media state: $e');
      }

      if (_achievementListener != null) {
        try {
          await _achievementListener!.cancel();
        } catch (e) {
          debugPrint('Error canceling achievement listener: $e');
        }
        _achievementListener = null;
      }
      _achievementListener = achievementsState.unlockedAchievementsStream.listen((achievement) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          context.read<NotificationQueue>().queueAchievement(achievement.name);
          try {
            await feedState.addFeedEvent(
              FeedEvent(
                feedUser: this.user, // Use class field
                id: '',
                objectId: achievement.id,
                eventType: 'achievement',
                payload: {
                  'achievement_name': achievement.name,
                  'achievement_desc': achievement.description,
                  'achievement_badge_path': achievement.iconPath,
                  'is_hidden': achievement.isHidden,
                },
                isBackfill: false
              )
            );
          } catch (e) {
            debugPrint('Error adding achievement feed event: $e');
          }
        });
      });
      
      try {
        await achievementsState.loadFromSupabase();
        debugPrint('Loaded ${achievementsState.achievements.length} achievements');
        await achievementsState.checkAndUnlockShopAchievement(shopState);
        await achievementsState.checkAndUnlockDrinkAchievement(drinkState);
        await achievementsState.checkAndUnlockFriendAchievement(friendState);
        await achievementsState.checkAndUnlockNotesAchievement(drinkState);
        await achievementsState.checkAndUnlockMaxDrinksShopAchievement(drinkState);
        await achievementsState.checkAndUnlockMediaUploadAchievement(shopMediaState);
        await achievementsState.checkAndUnlockBrandAchievement(shopState);
        await achievementsState.checkAndUpdateAllAchievement();
        debugPrint('Loaded ${achievementsState.userAchievements.length} user achievements');
      } catch (e) {
        debugPrint('Error loading achievements state: $e');
      }

      try {
        await feedState.fetchFeed();
        debugPrint('Loaded ${feedState.feed.length} feed events');
      } catch (e) {
        debugPrint('Error loading feed state: $e');
      }

      if (mounted) {
        setState(() {
          this.user = user;
          _session = session;
          _isReady = true;
        });
      }
    } else {
      _resetAllStates();
      if (mounted) {
        setState(() {
          _session = null;
          _isReady = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      !_isReady
        ? SplashPage()
        : (_session == null ? const AuthPage() : HomePage(user: user));
  }
}

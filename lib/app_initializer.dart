import 'dart:async';
import 'package:bobadex/helpers/show_snackbar.dart';
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
  bool _navigated = false;

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
    if (_navigated) return;
    debugPrint('Received deep link: $link');
    final uri = Uri.parse(link);
    final fragment = uri.fragment;
    if (fragment.isEmpty) return;

    final params = Uri.splitQueryString(fragment);

    try {
      if (params.containsKey('error_code')) {
        final errorDesc = params['error_description'] ?? 'Verification failed';
        debugPrint('Email verification error: ${params['error_code']} - $errorDesc');
        if (mounted) {
          context.read<NotificationQueue>().queue(errorDesc, SnackType.error);
        }
        return;
      }

      // Handle successful confirmation
      if (params.containsKey('access_token') && params.containsKey('refresh_token')) {
        await Supabase.instance.client.auth.setSession(
          params['refresh_token']!,
        );
        debugPrint('Session restored from confirmation link!');

        if (mounted) await context.read<UserState>().loadFromSupabase();
        
        if (mounted) {
          _navigated = true;
          context.read<NotificationQueue>().queue('Email verified successfully!', SnackType.success);
          Navigator.of(context).pushReplacementNamed('/home');
        }
        return;
      }

      debugPrint('Unknown deep link params: $params');
      if (mounted) {
        context.read<NotificationQueue>().queue('Invalid or expired verification link', SnackType.error);
      }
    } catch (e) {
      debugPrint('Failed to handle auth deep link: $e');
      if (mounted) {
        context.read<NotificationQueue>().queue('Failed to verify your account. Please try again.', SnackType.error);
      }
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

      await userState.loadFromSupabase();

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
          context.read<NotificationQueue>().queue(
            'Some data failed to load. Try refreshing.',
            SnackType.error,
          );
        }
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

import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/push/push_registration.dart';
import 'package:bobadex/helpers/go_router.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/notification_consumer.dart';
import 'package:bobadex/ui/theme/boba_theme_builder.dart';
import 'package:bobadex/ui/theme/boba_themes.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_initializer.dart';
import 'package:provider/provider.dart';

class BobadexApp extends StatefulWidget {
  const BobadexApp({super.key});
  @override
  State<BobadexApp> createState() => _BobadexAppState();
}

class _BobadexAppState extends State<BobadexApp> {
  late final FirebaseAnalytics _fa;
  late final AnalyticsService _analytics;
  late final FirebaseAnalyticsObserver _observer;
  late final AuthState _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _fa = FirebaseAnalytics.instance;
    _analytics = AnalyticsService(_fa);
    _observer = FirebaseAnalyticsObserver(analytics: _fa);
    _auth = AuthState();
    _router = buildRouter(auth: _auth, observers: [_observer]);
    PushRegistration.listen();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AnalyticsService>.value(value: _analytics),
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => DrinkState()),
        ChangeNotifierProvider(create: (_) => ShopState()),
        ChangeNotifierProvider(create: (_) => BrandState()),
        ChangeNotifierProvider(create: (_) => FriendState()),
        Provider(create: (_) => UserStatsCache()),
        ChangeNotifierProvider(create: (_) => ShopMediaState()),
        ChangeNotifierProvider(create: (_) => AchievementsState()),
        ChangeNotifierProvider(create: (_) => FeedState()),
        Provider(create: (_) => CityDataProvider()),
      ],
      child: Builder(
        builder: (context) {
          final themeSlug = context.select<UserState, String>(
            (s) => s.current.themeSlug,
          );
          final theme = BobaThemes.resolve(themeSlug);
          return MaterialApp.router(
            title: 'Bobadex',
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            locale: Locale('en'),
            theme: BobaThemeBuilder.build(theme),
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const AppInitializer(),
                  const NotificationConsumer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:bobadex/main.dart';
import 'package:bobadex/pages/home_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/city_data_provider.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:bobadex/widgets/notification_consumer.dart';
import 'package:flutter/material.dart';
import 'app_initializer.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';

class BobadexApp extends StatelessWidget {
  const BobadexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserState()),
        ChangeNotifierProvider(create: (_) => DrinkState()),
        ChangeNotifierProvider(create: (_) => ShopState()),
        ChangeNotifierProvider(create: (_) => BrandState()),
        ChangeNotifierProvider(create: (_) => FriendState()),
        ChangeNotifierProvider(create: (_) => UserStatsCache()),
        ChangeNotifierProvider(create: (_) => ShopMediaState()),
        ChangeNotifierProvider(create: (_) => AchievementsState()),
        ChangeNotifierProvider(create: (_) => FeedState()),
        ChangeNotifierProvider(create: (_) => CityDataProvider()),
        ChangeNotifierProvider(create: (_) => NotificationQueue()),
      ],
      child: Consumer<UserState>(
        builder: (context, userState, _) {
          final themeColor = Constants.getThemeColor(userState.user.themeSlug);
          return MaterialApp(
            title: 'Bobadex',
            routes: {
              '/home': (context) => HomePage(user: userState.user),
            },
            navigatorKey: navigatorKey,
            theme: ThemeData(
              scaffoldBackgroundColor: themeColor.shade50,
              dialogTheme: DialogThemeData(
                backgroundColor: themeColor.shade50,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: themeColor.shade50,
                foregroundColor: Colors.black,
                elevation: 0,
                scrolledUnderElevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  textStyle: WidgetStatePropertyAll<TextStyle>(
                    TextStyle(fontWeight: FontWeight.w500)
                  )
                )
              ),
              cardTheme: CardThemeData(color: themeColor.shade100),
              textButtonTheme: TextButtonThemeData(
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  textStyle: WidgetStatePropertyAll<TextStyle>(
                    TextStyle(fontWeight: FontWeight.w500)
                  )
                )
              )
            ),
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!,
            ),
            home: Stack(
              children: [
                AppInitializer(),
                NotificationConsumer(),
              ]
            ),
          );
        },
      ),
    );
  }
}

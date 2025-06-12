import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
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
      ],
      child: Consumer<UserState>(
        builder: (context, userState, _) {
          final themeColor = Constants.getThemeColor(userState.user.themeSlug);
          return MaterialApp(
            title: 'Bobadex',
            theme: ThemeData(
              scaffoldBackgroundColor: themeColor.shade50,
              appBarTheme: AppBarTheme(
                backgroundColor: themeColor.shade50,
                foregroundColor: Colors.black,
              ),
              cardTheme: CardTheme(color: themeColor.shade100),
            ),
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!,
            ),
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}

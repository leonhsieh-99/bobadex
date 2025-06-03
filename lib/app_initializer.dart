import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/user_state.dart';
import 'pages/splash_page.dart';
import 'state/drink_state.dart';
import 'state/shop_state.dart';
import 'config/constants.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isReady = false;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final userState = context.read<UserState>();
    final drinkState = context.read<DrinkState>();
    final shopState = context.read<ShopState>();

    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      _session = currentSession;

      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        setState(() {
          _session = data.session;
        });
      });
    } catch (e) {
      print('Error during app initialization: $e');
    }

    try {
      await userState.loadFromSupabase();
      print('Loaded user state');
    } catch (e) {
      print('Error loading user state: $e');
    }

    try {
      await drinkState.loadFromSupabase();
      print('Loaded ${drinkState.all.length} drinks');
    } catch (e) {
      print('Error loading drinks: $e');
    }

    try {
      await shopState.loadFromSupabase();
      print('Loaded ${shopState.all.length} shops');
    } catch (e) {
      print('Error loading drinks: $e');
    }

    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final user = userState.user;
    final themeColor = Constants.getThemeColor(user.themeSlug);

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
      home: !_isReady
          ? const SplashPage()
          : (_session == null ? const AuthPage() : HomePage(session: _session!)),
    );
  }
}

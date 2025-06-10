import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/user_state.dart';
import 'pages/splash_page.dart';
import 'state/drink_state.dart';
import 'state/brand_state.dart';
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
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      _session = currentSession;

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final userState = context.read<UserState>();
        final drinkState = context.read<DrinkState>();
        final shopState = context.read<ShopState>();
        final brandState = context.read<BrandState>();
        if (session != null) {
          _session = session; // update early
          try {
            await userState.loadFromSupabase();
            print('Loaded user state');
          } catch (e) {
            print('Error loading user state: $e');
          }

          // Guard: don't continue unless userState.user exists
          final user = context.read<UserState>().user;
          if (user.id.isEmpty) {
            print('No valid user loaded — skipping rest');
            return;
          }

          try {
            await drinkState.loadFromSupabase();
            print('Loaded ${drinkState.all.length} drinks');
          } catch (e) {
            print('Error loading drinks: $e');
          }

          try {
            await brandState.loadFromSupabase();
            print('Loaded ${brandState.all.length} brands');
          } catch (e) {
            print('Error loading brands: $e');
          }

          try {
            await shopState.loadFromSupabase();
            print('Loaded ${shopState.all.length} shops');
          } catch (e) {
            print('Error loading shops: $e');
          }

          if (mounted) {
            setState(() {
              _isReady = true;
            });
          }
        } else {
          userState.reset();
          drinkState.reset();
          shopState.reset();
          brandState.reset();
          if (mounted) setState(() => _isReady = true);
        }
        if (mounted) {
          setState(() {
            _session = session;
            _isReady = true;
          });
        }
      });
    } catch (e) {
      print('Error during app initialization: $e');
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

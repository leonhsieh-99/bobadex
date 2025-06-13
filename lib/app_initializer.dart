import 'package:bobadex/state/friend_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/user_state.dart';
import 'pages/splash_page.dart';
import 'state/drink_state.dart';
import 'state/brand_state.dart';
import 'state/shop_state.dart';
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

    void _resetAllStates() {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        p.Provider.of<UserState>(context, listen: false).reset();
        p.Provider.of<DrinkState>(context, listen: false).reset();
        p.Provider.of<ShopState>(context, listen: false).reset();
        p.Provider.of<BrandState>(context, listen: false).reset();
        p.Provider.of<FriendState>(context, listen: false).reset();
      });
    }

  Future<void> _initializeSession() async {
    try {
      final supabase = Supabase.instance.client.auth;

      void handleSession(Session? session) async {
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

          try {
            await userState.loadFromSupabase();
            print('Loaded user state');
          } catch (e) {
            print('Error loading user state: $e');
          }

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

          try {
            await friendState.loadFromSupabase();
            print('Loaded ${friendState.allFriendships.length} friendships');
          } catch (e) {
            print('Error loading friend state: $e');
          }
          if (mounted) {
            setState(() {
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

      supabase.onAuthStateChange.listen((data) {
        handleSession(data.session);
      });

      handleSession(supabase.currentSession);

    } catch (e) {
      print('Error during app initialization: $e');
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return
      !_isReady
        ? const SplashPage()
        : (_session == null ? const AuthPage() : HomePage(session: _session!));
  }
}

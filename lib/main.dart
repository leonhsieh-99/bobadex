
import 'package:bobadex/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bobadex.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase configuration. Please check your .env file.');
    }

    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      } on FirebaseException catch (e) {
        if (e.code == 'duplicate-app') {
          debugPrint('Firebase already initialized. Apps: ${Firebase.apps.map((a) => a.name).toList()}');
        } else {
          rethrow;
        }
      }
    }

    await Supabase.initialize(
      url: supabaseUrl, 
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      )
    );

    await Hive.initFlutter();
    final prefsBox = await Hive.openBox('prefs');

    final analyticsEnabled = (prefsBox.get('analytics_enabled') as bool?) ?? true;
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);

    await SentryFlutter.init(
      (o) {
        o.dsn = dotenv.env['SENTRY_DSN'];
        o.tracesSampleRate = 0.1;
      },
      appRunner: () => runApp(const BobadexApp()),
    );
  } catch (e) {
    debugPrint('Failed to initialize app: $e');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}


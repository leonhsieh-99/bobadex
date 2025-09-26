import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bobadex.dart';
import 'firebase_options.dart';

void _runBootstrapApp() => runApp(const _BootstrapApp());

Future<void> _bootstrap() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing Supabase configuration. Please check your .env file.');
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  await Hive.initFlutter();
  final prefsBox = await Hive.openBox('prefs');
  final analyticsEnabled = (prefsBox.get('analytics_enabled') as bool?) ?? true;
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final dsn = dotenv.env['SENTRY_DSN'] ?? '';

  if (dsn.isNotEmpty) {
    await SentryFlutter.init(
      (o) {
        o.dsn = dsn;
        o.tracesSampleRate = 0.1;
      },
      appRunner: _runBootstrapApp,
    );
  } else {
    _runBootstrapApp();
  }
}

class _BootstrapApp extends StatelessWidget {
  const _BootstrapApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snap.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Failed to initialize app:\n${snap.error}'),
                ),
              ),
            ),
          );
        }
        return BobadexApp();
      },
    );
  }
}

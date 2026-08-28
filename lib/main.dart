import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bobadex.dart';
import 'firebase_options.dart';
import 'helpers/app_prefs.dart';

void _runBootstrapApp() => runApp(const _BootstrapApp());

Future<void> _bootstrap() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase configuration. Run with --dart-define-from-file=.env.dev or .env.prod',
    );
  }

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );

  final analyticsEnabled = await AppPrefs.analyticsEnabled();
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const dsn = String.fromEnvironment('SENTRY_DSN');

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

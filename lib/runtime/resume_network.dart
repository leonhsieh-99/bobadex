import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// How long the app can sit in the background before its sockets are dropped.
///
/// iOS freezes the process and leaves those connections open. The next request
/// then waits forever, which is the hang that goes away after a force-quit.
const staleNetworkResetAfter = Duration(minutes: 1);

/// Bounds a single Supabase request so a dead socket cannot stall the app.
const supabaseRequestTimeout = Duration(seconds: 20);

/// Shared by [Supabase.initialize] so a resume can replace the live client.
final supabaseHttpClient = ResilientHttpClient(timeout: supabaseRequestTimeout);

/// HTTP client that can discard connections frozen while the app was suspended.
class ResilientHttpClient extends http.BaseClient {
  ResilientHttpClient({
    http.Client Function()? createClient,
    this.timeout = supabaseRequestTimeout,
  }) : _createClient = createClient ?? http.Client.new,
       _inner = (createClient ?? http.Client.new)();

  final http.Client Function() _createClient;
  final Duration timeout;
  http.Client _inner;

  /// Closes the current client so in-flight requests fail, then opens a fresh one.
  void dropStaleConnections() {
    final previous = _inner;
    _inner = _createClient();
    previous.close();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeout);
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Drops frozen Supabase connections after a long background.
class ResumeNetworkObserver with WidgetsBindingObserver {
  ResumeNetworkObserver({
    DateTime Function()? now,
    void Function()? onStaleResume,
  }) : _now = now ?? DateTime.now,
       _onStaleResume = onStaleResume ?? recoverStaleSupabaseConnections;

  final DateTime Function() _now;
  final void Function() _onStaleResume;
  DateTime? _backgroundedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= _now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (_now().difference(backgroundedAt) < staleNetworkResetAfter) return;
    _onStaleResume();
  }
}

/// Fails requests stuck on sockets from before the app was suspended.
void recoverStaleSupabaseConnections() {
  supabaseHttpClient.dropStaleConnections();
  if (!Supabase.instance.isInitialized) return;
  // The auth client starts its own refresh on resume, after this observer.
  // Dropping the old client lets that refresh open a new socket.
}

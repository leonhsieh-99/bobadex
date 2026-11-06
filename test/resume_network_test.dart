import 'dart:async';

import 'package:bobadex/runtime/resume_network.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('a request that never returns is bounded by the timeout', () async {
    final client = ResilientHttpClient(
      createClient: _HangingClient.new,
      timeout: const Duration(milliseconds: 30),
    );

    await expectLater(
      client.send(http.Request('GET', Uri.parse('https://example.com'))),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('dropping stale connections closes the client that was in use', () {
    final clients = <_CloseTrackingClient>[];
    final client = ResilientHttpClient(
      createClient: () {
        final created = _CloseTrackingClient();
        clients.add(created);
        return created;
      },
    );

    client.dropStaleConnections();

    expect(clients, hasLength(2));
    expect(clients.first.closed, isTrue);
    expect(clients.last.closed, isFalse);
  });

  test('a short background does not reset the network', () {
    var recoveries = 0;
    var now = DateTime(2026, 11, 5, 12);
    final observer = ResumeNetworkObserver(
      now: () => now,
      onStaleResume: () => recoveries++,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 20));
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(recoveries, 0);
  });

  test('a long background resets the network on resume', () {
    var recoveries = 0;
    var now = DateTime(2026, 11, 5, 12);
    final observer = ResumeNetworkObserver(
      now: () => now,
      onStaleResume: () => recoveries++,
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
    now = now.add(staleNetworkResetAfter);
    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(recoveries, 1);
  });
}

class _HangingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return Completer<http.StreamedResponse>().future;
  }
}

class _CloseTrackingClient extends http.BaseClient {
  var closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(const Stream.empty(), 200);
  }

  @override
  void close() {
    closed = true;
  }
}

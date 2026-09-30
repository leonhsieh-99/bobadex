import 'dart:async';

import 'package:bobadex/helpers/ttl_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ttl cache reuses a fresh value and reloads after it expires', () async {
    var now = DateTime(2026, 1, 1);
    final cache = TtlCache<int>(
      ttl: const Duration(minutes: 2),
      clock: () => now,
    );
    var loads = 0;

    Future<int> load(int value) {
      loads++;
      return Future.value(value);
    }

    expect(await cache.get('a', () => load(1)), 1);
    expect(await cache.get('a', () => load(2)), 1);
    expect(loads, 1);

    now = now.add(const Duration(minutes: 2));
    expect(await cache.get('a', () => load(2)), 2);
    expect(loads, 2);
  });

  test('ttl cache shares one in-flight load', () async {
    final cache = TtlCache<int>();
    final gate = Completer<void>();
    var loads = 0;

    Future<int> load() async {
      loads++;
      await gate.future;
      return 4;
    }

    final first = cache.get('a', load);
    final second = cache.get('a', load);
    gate.complete();
    expect(await Future.wait([first, second]), [4, 4]);
    expect(loads, 1);
  });

  test('a failed load is not cached', () async {
    final cache = TtlCache<int>();
    var loads = 0;

    await expectLater(
      cache.get('a', () async {
        loads++;
        throw StateError('down');
      }),
      throwsStateError,
    );
    expect(
      await cache.get('a', () async {
        loads++;
        return 3;
      }),
      3,
    );
    expect(loads, 2);
  });

  test('invalidate drops one key', () async {
    final cache = TtlCache<int>(ttl: const Duration(minutes: 5));
    await cache.get('a', () async => 1);
    await cache.get('b', () async => 2);
    cache.invalidate('a');
    expect(await cache.get('a', () async => 9), 9);
    expect(await cache.get('b', () async => 8), 2);
  });
}

/// In-memory values that expire, with one in-flight load per key.
class TtlCache<T> {
  TtlCache({this.ttl = const Duration(minutes: 2), DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Duration ttl;
  final DateTime Function() _clock;
  final _values = <String, ({T value, DateTime at})>{};
  final _pending = <String, Future<T>>{};

  Future<T> get(String key, Future<T> Function() load) {
    final hit = _values[key];
    if (hit != null && _clock().difference(hit.at) < ttl) {
      return Future.value(hit.value);
    }
    return _pending.putIfAbsent(key, () => _store(key, load));
  }

  Future<T> _store(String key, Future<T> Function() load) async {
    try {
      final value = await load();
      _values[key] = (value: value, at: _clock());
      return value;
    } finally {
      _pending.remove(key);
    }
  }

  void invalidate([String? key]) {
    if (key == null) {
      _values.clear();
      return;
    }
    _values.remove(key);
  }
}

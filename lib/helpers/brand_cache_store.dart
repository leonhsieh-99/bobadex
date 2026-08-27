import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BrandCacheStore {
  static const _fileName = 'brand_cache.json';

  Map<String, dynamic>? _mem;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<Map<String, dynamic>> _load() async {
    if (_mem != null) return _mem!;
    try {
      final file = await _file();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          _mem = Map<String, dynamic>.from(decoded);
          return _mem!;
        }
      }
    } catch (_) {}
    _mem = <String, dynamic>{};
    return _mem!;
  }

  Future<dynamic> get(String key) async => (await _load())[key];

  Future<void> putAll(Map<String, dynamic> values) async {
    final map = await _load();
    map.addAll(values);
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(map));
  }
}

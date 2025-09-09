import 'package:bobadex/helpers/media_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRealtimeService {
  RealtimeChannel? _chInvalid;

  void start({
    required Future<void> Function(String deletedId) onDeleteById,
    void Function(String path)? onOwnMediaDeleted, // optional toast/UI
  }) {
    if (_chInvalid != null) return;
    final supa = Supabase.instance.client;

    _chInvalid = supa.channel('public:media_invalidation')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'media_invalidation',
        callback: (payload) async {
          final row    = payload.newRecord;
          final bucket = (row['bucket'] as String?) ?? 'media-uploads';
          final path   = row['path'] as String?;
          final id     = row['media_id'] as String?;

          if (path != null) {
            await evictAllVariants(path, bucket: bucket);
            onOwnMediaDeleted?.call(path); // show toast if you want
          }
          if (id != null) {
            await onDeleteById(id);        // remove from stores by ID
          }
        },
      )
      ..subscribe((status, err) {
        debugPrint('media_invalidation status: $status ${err ?? ""}');
      });
  }

  Future<void> stop() async {
    if (_chInvalid != null) {
      await Supabase.instance.client.removeChannel(_chInvalid!);
      _chInvalid = null;
    }
  }
}

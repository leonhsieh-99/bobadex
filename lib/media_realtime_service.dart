import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/media_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRealtimeService {
  RealtimeChannel? _chInvalid;
  bool _starting = false;
  bool _started  = false;

  bool get isStarted => _started;

  void start({
    required Future<void> Function(String deletedId) onDeleteById,
    void Function(String path)? onOwnMediaDeleted, // optional toast/UI
  }) {
    if (_started || _starting || _chInvalid != null) {
      debugPrint('MediaRealtimeService: already started/starting, skip');
      return;
    }
    
    final supa = Supabase.instance.client;

    final ch = supa.channel('public:media_invalidation');
    _chInvalid = ch;

    ch
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
            await evictAllThumbsFor(bucket: bucket, originalPath: path, sizes: Constants.thumbSizes);
            if (!path.startsWith('thumbs/')) {
              onOwnMediaDeleted?.call(path);
            }
          }
          if (id != null) await onDeleteById(id);
        },
      )
      ..subscribe((status, err) {
        debugPrint('media_invalidation status: $status ${err ?? ""}');
        if (status == RealtimeSubscribeStatus.subscribed) {
          _started = true;
          _starting = false;
        } else if (status == RealtimeSubscribeStatus.closed ||
                   status == RealtimeSubscribeStatus.channelError) {
          _started = false;
          _starting = false;
        }
      });
  }

  Future<void> stop() async {
    if (_chInvalid != null) {
      await Supabase.instance.client.removeChannel(_chInvalid!);
      _chInvalid = null;
    }
    _starting = false;
    _started  = false;
  }
}

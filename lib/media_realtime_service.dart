import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/media_cache.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaRealtimeService {
  RealtimeChannel? _chInvalid;
  bool _starting = false;
  bool _started  = false;
  bool _gaveUp = false;

  bool get isStarted => _started;

  void start({
    required Future<void> Function(String deletedId) onDeleteById,
    void Function(String path)? onOwnMediaDeleted, // optional toast/UI
  }) {
    if (_gaveUp || _started || _starting || _chInvalid != null) return;

    _starting = true;
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
        if (status == RealtimeSubscribeStatus.subscribed) {
          _started = true;
          _starting = false;
          return;
        }
        if (status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.channelError) {
          _started = false;
          _starting = false;
          if (_gaveUp) return;
          _gaveUp = true;
          debugPrint(
            'media_invalidation unavailable, stopping retries: ${err ?? status}',
          );
          final channel = _chInvalid;
          _chInvalid = null;
          if (channel != null) {
            Future<void>(() {
              Supabase.instance.client.removeChannel(channel);
            });
          }
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
    _gaveUp = false;
  }
}

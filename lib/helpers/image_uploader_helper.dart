import 'dart:io';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/media_cache.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as im;

class ImageUploaderHelper {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadImage({
    required File file,
    required String folder,
    int maxOriginalEdge = 1024, // cap long edge for bandwidth
  }) async {
    if (!await file.exists()) throw Exception('File does not exist');

    final uuid = const Uuid().v4();
    final originalPath = p.join(folder, '$uuid.jpg'); // normalize to jpg

    final src = await file.readAsBytes();
    final decoded = im.decodeImage(src);
    if (decoded == null) throw Exception('Unsupported image format');

    // Cap original long edge
    final w = decoded.width, h = decoded.height;
    final long = w > h ? w : h;
    final base = long > maxOriginalEdge
        ? (w >= h
            ? im.copyResize(decoded, width: maxOriginalEdge)
            : im.copyResize(decoded, height: maxOriginalEdge))
        : decoded;

    final origBytes = Uint8List.fromList(im.encodeJpg(base, quality: 85));

    // Precompute thumbs (square cover-crop)
    final Map<int, Uint8List> thumbBytes = {
      for (final s in Constants.thumbSizes)
        s: Uint8List.fromList(
          im.encodeJpg(
            im.copyResizeCropSquare(base, size: s),
            quality: 80,
          ),
        ),
    };

    final uploads = <Future<void>>[];

    uploads.add(_supabase.storage.from(Constants.imageBucket).uploadBinary(
      originalPath,
      origBytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
        upsert: false,
      ),
    ));

    for (final entry in thumbBytes.entries) {
      final size = entry.key;
      final bytes = entry.value;
      uploads.add(_supabase.storage.from(Constants.imageBucket).uploadBinary(
        'thumbs/s$size/$originalPath',
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
          upsert: true,
        ),
      ));
    }

    await Future.wait(uploads);

    return originalPath; // store in DB
  }

  static Future<void> deleteImage(
    String originalPath, {
    String bucket = Constants.imageBucket,
    List<int> sizes = Constants.thumbSizes,
    bool evictLocalCache = true,
  }) async {
    if (originalPath.isEmpty || originalPath.startsWith('/')) return;

    final paths = <String>[
      originalPath,
      for (final s in sizes) 'thumbs/s$s/$originalPath',
    ];

    try {
      await _supabase.storage.from(bucket).remove(paths);
    } catch (e) {
      // pass
    }

    if (evictLocalCache) {
      await evictAllThumbsFor(
        bucket: bucket,
        originalPath: originalPath,
        sizes: sizes,
      );
    }
  }

  static Future<void> deleteManyImages(
    Iterable<String> originalPaths, {
    String bucket = Constants.imageBucket,
    List<int> sizes = Constants.thumbSizes,
    int batch = 1000,
    bool evictLocalCache = true,
  }) async {
    // Build the full list once
    final all = <String>[];
    for (final path in originalPaths) {
      if (path.isEmpty || path.startsWith('/')) continue;
      all.add(path);
      for (final s in sizes) {
        all.add('thumbs/s$s/$path');
      }
    }
    // Chunk to stay under API limits
    for (var i = 0; i < all.length; i += batch) {
      final chunk = all.sublist(i, (i + batch).clamp(0, all.length));
      try {
        await _supabase.storage.from(bucket).remove(chunk);
      } catch (_) {}
    }
    if (evictLocalCache) {
      for (final p in originalPaths) {
        await evictAllThumbsFor(bucket: bucket, originalPath: p, sizes: sizes);
      }
    }
  }
}

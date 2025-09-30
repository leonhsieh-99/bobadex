import 'package:bobadex/helpers/url_helper.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart' show PaintingBinding, NetworkImage;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseProjectUrl = dotenv.env['SUPABASE_URL'];

Future<void> evictOneUrl(String url) async {
  try { await DefaultCacheManager().removeFile(url); } catch (_) {}
  try { await CachedNetworkImage.evictFromCache(url); } catch (_) {}
  try { PaintingBinding.instance.imageCache.evict(NetworkImage(url)); } catch (_) {}
}

/// Evict all static thumbs (for provided sizes) + original.
Future<void> evictAllThumbsFor({
  required String bucket,
  required String originalPath,
  required List<int> sizes,
}) async {
  final originalUrl = publicUrl(bucket, originalPath);
  await evictOneUrl(originalUrl);

  for (final s in sizes) {
    final tUrl = publicUrl(bucket, thumbPath(originalPath, s));
    await evictOneUrl(tUrl);
  }
}
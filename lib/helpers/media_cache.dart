import 'package:bobadex/config/constants.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart' show PaintingBinding, NetworkImage;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseProjectUrl = dotenv.env['SUPABASE_URL'];

String renderUrl(
  String bucket,
  String path, {
  required int w,
  required int h,
  String resize = 'cover',
  int quality = 80,
}) {
  return '$supabaseProjectUrl/storage/v1/render/image/public/$bucket/$path'
      '?width=$w&height=$h&resize=$resize&quality=$quality';
}

Future<void> evictOneUrl(String url) async {
  try { await DefaultCacheManager().removeFile(url); } catch (_) {}
  try { await CachedNetworkImage.evictFromCache(url); } catch (_) {}
  try { PaintingBinding.instance.imageCache.evict(NetworkImage(url)); } catch (_) {}
}

/// Evict all known size variants for a given storage path.
Future<void> evictAllVariants(String path, {String bucket = 'media-uploads'}) async {
  final variants = Constants.allVariants();
  for (final (w, h) in variants) {
    final url = renderUrl(bucket, path, w: w, h: h);
    await evictOneUrl(url);
  }
}
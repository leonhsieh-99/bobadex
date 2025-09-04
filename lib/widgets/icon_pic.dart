import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kSquareBuckets = [64, 128, 160, 256];

int _nearestPx(int v, List<int> buckets) =>
    buckets.reduce((a, b) => (v - a).abs() < (v - b).abs() ? a : b);

class IconPic extends StatelessWidget {
  final String? path;
  final double size;
  final int quality;

  const IconPic({
    super.key,
    required this.path,
    this.size = 70,
    this.quality = 80,
  });

  String? _originalUrl() {
    if (path == null || path!.isEmpty) return null;
    return Supabase.instance.client.storage.from('shop-media').getPublicUrl(path!);
  }

  String? _transformedUrl(BuildContext context, {required int px}) {
    final base = _originalUrl();
    if (base == null) return null;

    final u = Uri.parse(base);
    final renderPath = u.path.replaceFirst(
      '/storage/v1/object/public/',
      '/storage/v1/render/image/public/',
    );
    final q = quality.clamp(1, 100);

    return Uri(
      scheme: u.scheme,
      host: u.host,
      path: renderPath,
      queryParameters: {
        'width': '$px',
        'height': '$px',
        'resize': 'contain',
        'quality': '$q',
      },
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final target = (size * dpr).round();
    final px = _nearestPx(target, _kSquareBuckets);

    final tUrl = _transformedUrl(context, px: px);
    final oUrl = _originalUrl();

    Widget child;
    if (tUrl != null) {
      child = CachedNetworkImage(
        imageUrl: tUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: px,
        memCacheHeight: px,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => (oUrl != null)
            ? CachedNetworkImage(
                imageUrl: oUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      );
    } else {
      child = _fallback();
    }
    return ClipRRect(child: child);
  }

  Widget _placeholder() => SizedBox(
        width: size,
        height: size,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _fallback() => Container(
        width: size,
        height: size,
        color: Colors.grey[300],
        child: Icon(Icons.store, size: size * 0.5, color: Colors.grey[700]),
      );
}

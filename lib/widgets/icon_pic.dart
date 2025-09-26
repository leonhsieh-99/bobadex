import 'package:bobadex/config/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IconPic extends StatelessWidget {
  final String? path;
  final double size;
  final int quality;
  final bool circular;

  const IconPic({
    super.key,
    required this.path,
    this.size = 70,
    this.quality = 80,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _wrap(_fallback());
    }

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final px = _nearestPx((size * dpr).round(), _kSquareBuckets);

    final tUrl = _transformedUrl(px: px);
    final oUrl = _originalUrl();

    final Widget img = CachedNetworkImage(
      imageUrl: tUrl ?? oUrl ?? '',
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: px,
      memCacheHeight: px,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        if (tUrl != null && oUrl != null && tUrl != oUrl) {
          return CachedNetworkImage(
            imageUrl: oUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            memCacheWidth: px,
            memCacheHeight: px,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholderFadeInDuration: Duration.zero,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _fallback(),
          );
        }
        return _fallback();
      },
    );

    return _wrap(img);
  }

  Widget _wrap(Widget child) =>
      circular ? ClipOval(child: child) : ClipRRect(borderRadius: BorderRadius.circular(12), child: child);

  Widget _placeholder() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.05),
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circular ? null : BorderRadius.circular(12),
    ),
  );

  Widget _fallback() => Image.asset(
    'lib/assets/default_icon.png',
    width: size,
    height: size,
    fit: BoxFit.cover,
  );

  String? _originalUrl() {
    try {
      return Supabase.instance.client.storage.from('shop-media').getPublicUrl(path!);
    } catch (_) {
      return null;
    }
  }

  String? _transformedUrl({required int px}) {
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
      port: u.hasPort ? u.port : null,
      path: renderPath,
      queryParameters: {
        'width': '$px',
        'height': '$px',
        'resize': 'contain',
        'quality': '$q',
      },
    ).toString();
  }
}

// --- helpers ---

const _kSquareBuckets = Constants.avatarSmall;

int _nearestPx(int v, List<int> buckets) =>
    buckets.reduce((a, b) => (v - a).abs() <= (v - b).abs() ? a : b);

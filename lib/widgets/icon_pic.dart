import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class IconPic extends StatelessWidget {
  final String? path;
  final double size;
  final bool circular;

  const IconPic({
    super.key,
    required this.path,
    this.size = 70,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _wrap(_fallback());
    }

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final px  = pickSquareSize(size, dpr, Constants.thumbSizes);

    final sizedThumb = publicUrl(Constants.iconBucket, thumbPath(path!, px));
    final smallerThumb = publicUrl(Constants.iconBucket, thumbPath(path!, 256)); // common default
    final original = publicUrl(Constants.iconBucket, path!);

    final img = CachedNetworkImage(
      imageUrl: sizedThumb,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: px,
      memCacheHeight: px,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => CachedNetworkImage(
        imageUrl: smallerThumb,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: 256,
        memCacheHeight: 256,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => CachedNetworkImage(
          imageUrl: original,   // last resort
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      ),
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
}

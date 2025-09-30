import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ThumbPic extends StatelessWidget {
  final String? path;
  final double size;
  final String? initials;
  final VoidCallback? onTap;

  const ThumbPic({
    super.key,
    required this.path,
    this.size = 40,
    this.initials,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return _fallback();
    }

    final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
    final px  = pickSquareSize(size, dpr, Constants.thumbSizes);

    final sizedThumb = publicUrl(Constants.imageBucket, thumbPath(path!, px));
    final smallerThumb = publicUrl(Constants.imageBucket, thumbPath(path!, 256)); // common default
    final original = publicUrl(Constants.imageBucket, path!);

    final inner = CachedNetworkImage(
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

    return GestureDetector(onTap: onTap, child: ClipOval(child: inner));
  }

  Widget _placeholder() => SizedBox(
    width: size, height: size,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  Widget _fallback() {
    final text = (initials ?? '').trim();
    if (text.isNotEmpty) {
      final abbr = _oneChar(text).toUpperCase();
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade400),
        alignment: Alignment.center,
        child: Text(
          abbr,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: size * 0.45),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
      child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
    );
  }

  String _oneChar(String s) {
    final cleaned = s.replaceAll(RegExp(r'\s+'), '');
    return cleaned.characters.take(1).toString();
  }
}

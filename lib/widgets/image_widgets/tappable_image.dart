import 'package:bobadex/helpers/build_transformed_url.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _originalUrl(String path) {
  return Supabase.instance.client.storage.from('media-uploads').getPublicUrl(path);
}

class TappableImage extends StatelessWidget {
  final ShopMedia media;
  final VoidCallback? onTap;
  final bool selected;
  final bool selectable;
  final double height;
  final double width;
  final bool useHero;

  const TappableImage({
    super.key,
    required this.media,
    this.onTap,
    this.selected = false,
    this.selectable = false,
    this.height = 100,
    this.width = 100,
    this.useHero = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    try {
      if (media.isPending && media.localFile != null) {
        image = Image.file(
          media.localFile!,
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, err, __) {
            debugPrint("Failed to load local image: $err");
            return const Icon(Icons.broken_image, size: 40);
          },
        );
      } else {
        final path = media.imagePath;
        final hasPath = path.isNotEmpty;
        final tUrl = hasPath
            ? buildTransformedUrl(
                bucket: 'media-uploads',
                path: path,
                resize: 'cover',
                quality: 100
              )
            : null;
        final oUrl = (path.isNotEmpty) ? _originalUrl(path) : null;

        Widget net = (tUrl != null)
          ? CachedNetworkImage(
              imageUrl: tUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(width, height),
              errorWidget: (_, __, ___) => (oUrl != null)
                  ? CachedNetworkImage(
                      imageUrl: oUrl,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(width, height),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : const SizedBox.shrink(),
            )
          : const SizedBox.shrink();

        image = useHero ? Hero(tag: media.id, child: net) : net;
      }
    } catch (e) {
      debugPrint("Error building image widget: $e");
      image = const Icon(Icons.broken_image, size: 40);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),

          // Pending overlay
          if (media.isPending && media.localFile != null)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

          // Selection highlight
          if (selectable && selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 3),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black26,
                ),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 36),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(double w, double h) => Container(
      width: w,
      height: h,
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator()),
    );
}
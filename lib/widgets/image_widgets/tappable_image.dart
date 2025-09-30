import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/url_helper.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
        final sized = publicUrl(Constants.imageBucket, thumbPath(path, 512));
        final orig  = publicUrl(Constants.imageBucket, path);

        Widget net = CachedNetworkImage(
          imageUrl: sized,
          width: width,
          height: height,
          fit: BoxFit.cover,
          memCacheWidth: 512,
          memCacheHeight: 512,
          placeholder: (_, __) => _placeholder(width, height),
          errorWidget: (_, __, ___) => CachedNetworkImage(
            imageUrl: orig,
            width: width,
            height: height,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(width, height),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        );

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
          if (media.isPending && media.localFile != null)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
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

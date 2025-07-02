import 'package:bobadex/models/shop_media.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TappableImage extends StatelessWidget {
  final ShopMedia media;
  final VoidCallback? onTap;
  final bool selected;
  final bool selectable;
  final double thumbSize;

  const TappableImage({
    super.key,
    required this.media,
    this.onTap,
    this.selected = false,
    this.selectable = false,
    this.thumbSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (media.isPending && media.localFile != null) {
      image = Image.file(media.localFile!, fit: BoxFit.cover, width: thumbSize, height: thumbSize);
    } else {
      image = CachedNetworkImage(
        imageUrl: media.thumbUrl,
        fit: BoxFit.cover,
        width: thumbSize,
        height: thumbSize,
        placeholder: (c, url) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (c, url, err) => Icon(Icons.broken_image),
      );
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
            Positioned.fill(child: Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            )),
          // Selection highlight
          if (selectable && selected)
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 3),
                borderRadius: BorderRadius.circular(10),
                color: Colors.black26,
              ),
              child: Icon(Icons.check_circle, color: Colors.white, size: 36),
            )),
        ],
      ),
    );
  }
}

import 'package:bobadex/models/shop_media.dart';
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
    if (media.isPending && media.localFile != null) {
      image = Image.file(media.localFile!, fit: BoxFit.cover, width: width, height: height);
    } else {
      if (useHero) {
        image = Hero(
          tag: media.id,
          child: Image.network(
            media.thumbUrl,
            fit: BoxFit.cover,
            width: width,
            height: height,
          ),
        );
      } else {
        image = Image.network(
          media.thumbUrl,
          fit: BoxFit.cover,
          width: width,
          height: height,
        );
      }
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

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
    try {
      if (media.isPending && media.localFile != null) {
        image = Image.file(
          media.localFile!, 
          fit: BoxFit.cover, 
          width: width, 
          height: height,
          errorBuilder: (context, error, stackTrace) {
            debugPrint("Failed to load local image: $error");
            return Icon(Icons.broken_image, size: 40);
          }
        );
      } else {
        if (useHero) {
          image = Hero(
            tag: media.id,
            child: Image.network(
              media.thumbUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("Failed to load image: $error");
                return Icon(Icons.broken_image, size: 40);
              }
            ),
          );
        } else {
          image = Image.network(
            media.thumbUrl,
            fit: BoxFit.cover,
            width: width,
            height: height,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint("Failed to load image: $error");
              return Icon(Icons.broken_image, size: 40);
            }
          );
        }
      }
    } catch (e) {
      debugPrint("Error building image widget: $e");
      image = Icon(Icons.broken_image, size: 40);
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

class SkeletonTappableImage extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonTappableImage({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
        ),
        child: Stack(
          children: [
            // Optional: add a subtle shimmer with AnimatedContainer or shimmer package
            // For now, just a static box
            Center(
              child: Icon(Icons.image, color: Colors.grey[400], size: width * 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

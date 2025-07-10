import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/tappable_image.dart';
import 'package:flutter/material.dart';

class HorizontalPhotoPreview extends StatelessWidget {
  final List<ShopMedia> shopMediaList;
  final int maxPreview;
  final VoidCallback? onViewAll;
  final double height;
  final double width;

  const HorizontalPhotoPreview ({
    super.key,
    required this.shopMediaList,
    this.maxPreview = 5,
    this.onViewAll,
    this.height = 100,
    this.width = 100,
  });

  void _onTap(context, int idx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          images: shopMediaList.map((m) =>
            m.localFile != null
              ? GalleryImage.file(m.localFile, comment: m.comment ?? '', userThumbUrl: m.userThumbUrl, userName: m.userDisplayName)
              : GalleryImage.network(m.imageUrl, comment: m.comment ?? '', userThumbUrl: m.userThumbUrl, userName: m.userDisplayName)
          ).toList(),
          initialIndex: idx,
          isCurrentUser: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showViewAll = shopMediaList.length > maxPreview;
    final visibleMedia = showViewAll ? shopMediaList.take(maxPreview - 1).toList() : shopMediaList;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleMedia.length + (showViewAll ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (showViewAll && index == visibleMedia.length) {
            return GestureDetector(
              onTap: onViewAll,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'View all',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () => _onTap(context, index),
            child: TappableImage(height: height, width: width, media: visibleMedia[index])
          );
        }
      ),
    );
  }
}

class HorizontalPreviewSkeleton extends StatelessWidget {
  final int count;
  final double height;
  final double width;
  const HorizontalPreviewSkeleton({super.key, this.count = 6, this.height = 100, this.width = 75});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}


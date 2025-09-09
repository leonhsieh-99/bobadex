import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/tappable_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GalleryGrid extends StatefulWidget {
  final List<ShopMedia> mediaList;
  final bool selectable;
  final bool isEditable;
  final bool isCurrentUser;
  final List<ShopMedia>? selected;
  final Future<void> Function(String mediaId)? onSetBanner;
  final VoidCallback? onEndReached;
  final ValueChanged<List<ShopMedia>>? onSelectionChanged;
  final bool? isLoadingMore;

  const GalleryGrid({
    super.key,
    required this.mediaList,
    this.isEditable = false,
    this.isCurrentUser = false,
    this.selected,
    this.selectable = false,
    this.onSetBanner,
    this.onEndReached,
    this.onSelectionChanged,
    this.isLoadingMore,
  });

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {
  void _onTap(int idx) async {
    if (widget.selectable) {
      final media = widget.mediaList[idx];
      List<ShopMedia> newSelected = List<ShopMedia>.from(widget.selected ?? []);
      if (newSelected.contains(media)) {
        newSelected.remove(media);
      } else {
        newSelected.add(media);
      }
      widget.onSelectionChanged?.call(newSelected);
    } else {
      // Build GalleryImage list
      final galleryImages = widget.mediaList.map((media) => GalleryImage(
        url: media.imageUrl,
        userImagePath: media.profileImagePath,
        userName: media.userDisplayName,
        id: media.id,
        comment: media.comment ?? '',
        visibility: media.visibility ?? 'private',
      )).toList();

      // Only if you want live edit, update the actual ShopMedia in the parent
      await Navigator.of(context).push<List<GalleryImage>>(
        MaterialPageRoute(
          builder: (_) => FullscreenImageViewer(
            images: galleryImages,
            initialIndex: idx, // start on tapped image
            mode: widget.isEditable ? FullscreenImageMode.edit : FullscreenImageMode.view,
            isCurrentUser: widget.isCurrentUser,
            onEdit: widget.isEditable
              ? (img, comment, visibility) async {
                try {
                  await context.read<ShopMediaState>().editMedia(img.id!, comment, visibility);
                  notify('Updated photo', SnackType.success);
                } catch (e) {
                  notify('Error updating comment: $e', SnackType.error);
                }
              }
            : null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final selected = widget.selected ?? [];
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (widget.onEndReached != null
          && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            widget.onEndReached!();
          }
          return false;
      },
      child: GridView.builder(
        itemCount: widget.mediaList.length + (widget.isLoadingMore == true ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12
        ),
        itemBuilder: (context, idx) {
          if (widget.isLoadingMore == true && idx == widget.mediaList.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final media = widget.mediaList[idx];
          final isSelected = selected.contains(media);
          return GestureDetector(
            onTap: () => _onTap(idx),
            onLongPress: () => _onTap(idx),
            child: Stack(
              children: [
                TappableImage(
                  media: media,
                  width: size.width/2,
                  height: size.width/2,
                  selected: isSelected,
                  selectable: widget.selectable,
                ),
                if (media.isBanner && widget.isEditable)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text('Banner', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                if (widget.isEditable && !media.isBanner)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white, size: 18),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'set_banner',
                          child: Text('Set as Banner'),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'set_banner' && widget.onSetBanner != null) {
                          await widget.onSetBanner!(media.id);
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      )
    );
  }
}

import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/tappable_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GalleryGrid extends StatefulWidget {
  final List<ShopMedia> mediaList;
  final bool selectable;
  final bool isEditable;
  final bool isCurrentUser;
  final List<ShopMedia>? selected;
  final Future<void> Function(String mediaId)? onSetBanner;
  final ValueChanged<List<ShopMedia>>? onSelectionChanged;

  const GalleryGrid({
    super.key,
    required this.mediaList,
    this.isEditable = false,
    this.isCurrentUser = false,
    this.selected,
    this.selectable = false,
    this.onSetBanner,
    this.onSelectionChanged,
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
      final galleryImages = widget.mediaList.map((media) => GalleryImage.network(
        media.imageUrl,
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
                final mediaIdx = widget.mediaList.indexWhere((m) => m.id == img.id);
                if (mediaIdx != -1) {
                  setState(() {
                    widget.mediaList[mediaIdx] = widget.mediaList[mediaIdx].copyWith(
                      comment: comment,
                      visibility: visibility,
                    );
                  });
                  try {
                    await Supabase.instance.client
                      .from('shop_media')
                      .update({
                        'comment': comment,
                        'visibility': visibility,
                      })
                      .eq('id', img.id);
                      if (mounted) showAppSnackBar(context, 'Updated photo', type: SnackType.success);
                  } catch (e) {
                    debugPrint('Error updating comment: $e');
                    if (mounted) showAppSnackBar(context, 'Error updating comment: $e', type: SnackType.error);
                  }
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
    final selected = widget.selected ?? [];
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.mediaList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8
      ),
      itemBuilder: (context, idx) {
        final media = widget.mediaList[idx];
        final isSelected = selected.contains(media);
        return GestureDetector(
          onTap: () => _onTap(idx),
          onLongPress: () => _onTap(idx), // Optionally, allow long-press for selection too
          child: Stack(
            children: [
              TappableImage(
                media: media,
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
    );
  }
}

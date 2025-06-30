import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/tappable_image.dart';
import 'package:flutter/material.dart';

class GalleryGrid extends StatefulWidget {
  final List<ShopMedia> mediaList;
  final bool selectable;
  final List<ShopMedia>? selected;
  final ValueChanged<List<ShopMedia>>? onSelectionChanged;

  const GalleryGrid({
    super.key,
    required this.mediaList,
    this.selected,
    this.selectable = false,
    this.onSelectionChanged,
  });

  @override
  State<GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<GalleryGrid> {

  void _onTap(int idx) {
    if (widget.selectable) {
      final media = widget.mediaList[idx];
      // Compute new selection list
      List<ShopMedia> newSelected = List<ShopMedia>.from(widget.selected ?? []);
      if (newSelected.contains(media)) {
        newSelected.remove(media);
      } else {
        newSelected.add(media);
      }
      widget.onSelectionChanged?.call(newSelected);
    } else {
      // Open fullscreen viewer
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullscreenImageViewer(
            images: widget.mediaList.map((m) =>
              m.localFile != null
                ? GalleryImage.file(m.localFile)
                : GalleryImage.network(m.imageUrl)
            ).toList(),
            initialIndex: idx,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected ?? [];
    return GridView.builder(
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
          child: TappableImage(
            media: media,
            selected: isSelected,
            selectable: widget.selectable,
          ),
        );
      },
    );
  }
}

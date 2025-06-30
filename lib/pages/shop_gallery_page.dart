import 'dart:io';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/gallery_grid.dart';
import 'package:bobadex/widgets/image_widgets/multiselect_image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopGalleryPage extends StatefulWidget {
  final List<ShopMedia> shopMediaList;
  final String? bannerMediaId;
  final Future<void> Function(String mediaId)? onSetBanner;
  final Future<void> Function(String mediaId)? onDelete;
  final bool isCurrentUser;
  final String? shopId;

  const ShopGalleryPage({
    super.key,
    required this.shopMediaList,
    this.bannerMediaId,
    this.onSetBanner,
    this.onDelete,
    required this.isCurrentUser,
    this.shopId,
  });

  @override
  State<ShopGalleryPage> createState() => _ShopGalleryPageState();
}

class _ShopGalleryPageState extends State<ShopGalleryPage> {
  bool _selecting = false;
  bool _isLoading = false;
  List<ShopMedia> _selected = [];

  void _onSelectionChanged(List<ShopMedia> selected) {
    setState(() {
      _selected = selected;
    });
  }

  void _deleteSelected(ShopMediaState state) async {
    setState(() {
      _isLoading = true;
    });
    try {
      for (final media in _selected) {
        await widget.onDelete?.call(media.id);
      }
      setState(() {
        _selecting = false;
        _selected = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Photos deleted'))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Failed to delete some photos'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPhotos(ShopMediaState shopMediaState) async {
    final images = await showDialog<List<File>>(
      context: context,
      builder: (context) => MultiselectImagePickerDialog(),
    );
    if (images == null || images.isEmpty) return;
    final bannerExists = shopMediaState.getBannerId(widget.shopId!) != null;

    for (int idx = 0; idx < images.length; idx++) {
      final file = images[idx];
      final tempId = UniqueKey().toString();

      // Add placeholder/pending media
      final pendingMedia = ShopMedia(
        id: tempId,
        shopId: widget.shopId!,
        userId: Supabase.instance.client.auth.currentUser!.id,
        imagePath: '',
        isBanner: idx == 0 && !bannerExists,
        localFile: file,
        isPending: true,
      );
      shopMediaState.addPendingMedia(pendingMedia);

      // Upload and replace pending with real
      ImageUploaderHelper.uploadImage(
        file: file,
        folder: 'shop-gallery',
        generateThumbnail: true,
      ).then((imagePath) async {
        try {
          // Create the real media (backend should return a unique id)
          final realMedia = ShopMedia(
            id: '', // id will be set by backend
            shopId: widget.shopId!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath,
            isBanner: idx == 0 && !bannerExists,
          );
          final insertedMedia = await shopMediaState.addMedia(realMedia);
          shopMediaState.replacePendingMedia(tempId, insertedMedia);
        } catch (e) {
          shopMediaState.removePendingMedia(tempId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed')),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.watch<ShopMediaState>();
    final shopMedia = (widget.isCurrentUser && widget.shopId != null)
      ? shopMediaState.getByShop(widget.shopId!)
      : widget.shopMediaList;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Photos'),
            actions: [
              if (widget.isCurrentUser && !_selecting)
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addPhotos(shopMediaState),
                ),
              if (widget.isCurrentUser && !_selecting)
                IconButton(
                  icon: Icon(Icons.select_all),
                  onPressed: () => setState(() {
                    _selecting = true;
                  })
                ),
              if (widget.isCurrentUser && _selecting)
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _selected.isEmpty ? null : () => _deleteSelected(shopMediaState),
                ),
              if (_selecting)
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selecting = false;
                    _selected.clear();
                  }),
                )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: shopMedia.isEmpty
              ? Center(child: const Text('No photos yet', style: Constants.emptyListTextStyle))
              : GalleryGrid(
                  mediaList: shopMedia,
                  selectable: _selecting,
                  selected: _selected,
                  onSelectionChanged: _onSelectionChanged,
                ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(child: CircularProgressIndicator()),
          ),
      ]
    );
  }
}

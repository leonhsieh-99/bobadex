import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/notification_queue.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
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
  final Future<List<ShopMedia>> Function(int offset, int limit)? onFetchMore;
  final bool isCurrentUser;
  final String? shopId;

  const ShopGalleryPage({
    super.key,
    required this.shopMediaList,
    this.bannerMediaId,
    this.onSetBanner,
    this.onDelete,
    this.onFetchMore,
    required this.isCurrentUser,
    this.shopId,
  });

  @override
  State<ShopGalleryPage> createState() => _ShopGalleryPageState();
}

class _ShopGalleryPageState extends State<ShopGalleryPage> {
  // for user's shop gallery
  bool _selecting = false;
  bool _isLoading = false;
  List<ShopMedia> _selected = [];
  // for infinite scroll
  List<ShopMedia> _mediaList = [];
  bool _isLoadingMore = false;
  int _offset = 0;
  static const int _limit = 30;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _mediaList = List.of(widget.shopMediaList);
    _offset = _mediaList.length;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || widget.onFetchMore == null) return;
    setState(() => _isLoadingMore = true);
    final next = await widget.onFetchMore!(_offset, _limit);
    setState(() {
      _mediaList.addAll(next);
      _offset += next.length;
      _isLoadingMore = false;
      _hasMore = next.length == _limit;
    });
  }

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
      if (mounted) context.read<NotificationQueue>().queue('Photos deleted', SnackType.success);
    } catch (e) {
      if (mounted) context.read<NotificationQueue>().queue('Error deleting photos', SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPhotos(ShopMediaState shopMediaState, AchievementsState achievementState) async {
    final images = await showDialog<List<GalleryImage>>(
      context: context,
      builder: (context) => MultiselectImagePickerDialog(),
    );
    if (images == null || images.isEmpty) return;
    final bannerExists = shopMediaState.getBannerId(widget.shopId!) != null;

    setState(() => _isLoading = true);

    final tempIds = <String>[];
    for (int idx = 0; idx < images.length; idx++) {
      final img = images[idx];
      final tempId = UniqueKey().toString();
      tempIds.add(tempId);

      // check for any existing pending images
      if (shopMediaState.all.any((m) => m.localFile == img.file && m.isPending)) {
        debugPrint('Duplicate pending upload detected, skipping');
        continue;
      }

      // Add placeholder/pending media
      final pendingMedia = ShopMedia(
        id: tempId,
        shopId: widget.shopId!,
        userId: Supabase.instance.client.auth.currentUser!.id,
        imagePath: '',
        comment: img.comment,
        visibility: img.visibility,
        isBanner: idx == 0 && !bannerExists,
        localFile: img.file,
        isPending: true,
      );
      shopMediaState.addPendingMedia(pendingMedia);
    }

    await Future.wait(
      images.asMap().entries.map((entry) async {
        final idx = entry.key;
        final img = entry.value;
        final tempId = tempIds[idx];

        try {
          final imagePath = await ImageUploaderHelper.uploadImage(
            file: img.file!,
            folder: 'shop-gallery',
            generateThumbnail: true,
          );

          final realMedia = ShopMedia(
            id: '', // Will be set by backend
            shopId: widget.shopId!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath,
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !bannerExists,
          );

          final insertedMedia = await shopMediaState.addMedia(realMedia);
          await achievementState.checkAndUnlockMediaUploadAchievement(shopMediaState);
          shopMediaState.replacePendingMedia(tempId, insertedMedia);
        } catch (e) {
          debugPrint('Error uploading image $idx: $e');
          shopMediaState.removePendingMedia(tempId);
          if (mounted) context.read<NotificationQueue>().queue('Upload failed', SnackType.error);
        }
      }),
    );
    
    setState(() => _isLoading = false);
    if (mounted) context.read<NotificationQueue>().queue('Images uploaded', SnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.watch<ShopMediaState>();
    final achievementState = context.watch<AchievementsState>();

    final userGallery = widget.isCurrentUser && widget.shopId != null;
    final shopMedia = userGallery
      ? shopMediaState.getByShop(widget.shopId!)
      : _mediaList;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Photos (${shopMedia.length.toString()})'),
            actions: [
              if (widget.isCurrentUser && !_selecting)
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _addPhotos(shopMediaState, achievementState),
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
                  isEditable: widget.isCurrentUser,
                  isCurrentUser: widget.isCurrentUser,
                  onSelectionChanged: _onSelectionChanged,
                  onSetBanner: widget.onSetBanner,
                  onEndReached: widget.onFetchMore != null ? _loadMore : null,
                  isLoadingMore: _isLoadingMore,
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

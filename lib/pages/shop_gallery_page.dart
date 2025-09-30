import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/image_widgets/fullscreen_image_viewer.dart';
import 'package:bobadex/widgets/image_widgets/gallery_grid.dart';
import 'package:bobadex/widgets/image_widgets/multiselect_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopGalleryPage extends StatefulWidget {
  final List<ShopMedia> shopMediaList;
  final Future<void> Function(String mediaId)? onSetBanner;
  final Future<void> Function(String mediaId)? onDelete;
  final Future<List<ShopMedia>> Function(int offset, int limit)? onFetchMore;
  final bool isCurrentUser;
  final String? shopId;
  final String? themeColor;

  const ShopGalleryPage({
    super.key,
    required this.shopMediaList,
    this.onSetBanner,
    this.onDelete,
    this.onFetchMore,
    required this.isCurrentUser,
    this.shopId,
    this.themeColor,
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
      notify('Photos deleted', SnackType.success);
    } catch (e) {
      notify('Error deleting photos', SnackType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPhotos(ShopMediaState shopMediaState, AchievementsState achievementState, AnalyticsService analytics) async {
    final images = await showDialog<List<GalleryImage>>(
      context: context,
      builder: (context) => MultiselectImagePicker(),
    );
    if (images == null || images.isEmpty) return;
    final hadBannerPath = shopMediaState.getBannerPath(widget.shopId!) != null;

    setState(() => _isLoading = true);

    final tempIds = <String>[];
    for (int idx = 0; idx < images.length; idx++) {
      final img = images[idx];
      final tempId = UniqueKey().toString();
      tempIds.add(tempId);

      // check for any existing pending images
      if (shopMediaState.getByShop(widget.shopId!).any((m) => m.localFile == img.file && m.isPending)) {
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
        isBanner: idx == 0 && !hadBannerPath,
        localFile: img.file,
        isPending: true,
      );
      shopMediaState.addPendingForShop(widget.shopId!, pendingMedia);
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
          );

          final realMedia = ShopMedia(
            id: '',
            shopId: widget.shopId!,
            userId: Supabase.instance.client.auth.currentUser!.id,
            imagePath: imagePath,
            comment: img.comment,
            visibility: img.visibility,
            isBanner: idx == 0 && !hadBannerPath,
          );

          await achievementState.checkAndUnlockMediaUploadAchievement();
          await shopMediaState.addMedia(realMedia, replacePendingId: tempId);
          await analytics.mediaUploaded(shopId: realMedia.id, count: 1);
        } catch (e) {
          debugPrint('Error uploading image $idx: $e');
          shopMediaState.removePendingForShop(widget.shopId!, tempId);
          notify('Upload failed', SnackType.error);
        }
      }),
    );
    
    setState(() => _isLoading = false);
    notify('Images uploaded', SnackType.success);
  }

  @override
  Widget build(BuildContext context) {
    final shopMediaState = context.watch<ShopMediaState>();
    final achievementState = context.watch<AchievementsState>();
    final analytics = context.read<AnalyticsService>();

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
                  onPressed: () => _addPhotos(shopMediaState, achievementState, analytics),
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
                  showUserInfo: false,
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

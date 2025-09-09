import 'package:bobadex/helpers/image_uploader_helper.dart';
import 'package:bobadex/helpers/retry_helper.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopMediaState extends ChangeNotifier {
  final List<ShopMedia> _shopMedia = [];
  bool _hasError = false;

  List<ShopMedia> get all => _shopMedia;
  bool get hasError => _hasError;

  ShopMedia? getById(String id) {
    return _shopMedia.firstWhereOrNull((m) => m.id == id);
  }

  List<ShopMedia> getByShop(String shopId) {
    return _shopMedia.where((m) => m.shopId == shopId).toList();
  }

  void addPendingMedia(ShopMedia pending) {
    _shopMedia.add(pending);
    notifyListeners();
  }

  void replacePendingMedia(String pendingId, ShopMedia realMedia) {
    final idx = _shopMedia.indexWhere((m) => m.id == pendingId);
    if (idx != -1) {
      _shopMedia[idx] = realMedia;
      notifyListeners();
    }
  }

  void removePendingMedia(String mediaId) {
    _shopMedia.removeWhere((m) => m.id == mediaId);
    notifyListeners();
  }

  String? getBannerId(String shopId) {
    return _shopMedia.firstWhereOrNull((sm) => sm.isBanner == true && sm.shopId == shopId)?.id;
  }

  Future<void> setBanner(String shopId, String mediaId) async {
    final newIndex = _shopMedia.indexWhere((sm) => sm.id == mediaId);
    final oldIndex = _shopMedia.indexWhere((sm) => sm.isBanner == true && sm.shopId == shopId);

    // Save old state for rollback
    bool hadOldBanner = oldIndex != -1;
    String? oldBannerId = hadOldBanner ? _shopMedia[oldIndex].id : null;

    // Optimistically update local state
    if (hadOldBanner) _shopMedia[oldIndex].isBanner = false;
    _shopMedia[newIndex].isBanner = true;
    notifyListeners();

    try {
      if (hadOldBanner && oldBannerId != null && oldBannerId != mediaId) {
        await Supabase.instance.client
          .from('shop_media')
          .update({'is_banner': false})
          .eq('id', oldBannerId);
      }
      await Supabase.instance.client
        .from('shop_media')
        .update({'is_banner': true})
        .eq('id', mediaId);
    } catch (e) {
      // Rollback local state if server update fails
      if (hadOldBanner) _shopMedia[oldIndex].isBanner = true;
      _shopMedia[newIndex].isBanner = false;
      notifyListeners();
      debugPrint('Error updating media banner: $e');
      rethrow;
    }
  }

  Future<void> editMedia(String id, String comment, String visibility) async {
    final mediaIdx = _shopMedia.indexWhere((m) => m.id == id);
    final tempMedia = _shopMedia[mediaIdx];
    _shopMedia[mediaIdx] = tempMedia.copyWith(comment: comment, visibility: visibility);
    notifyListeners();
    if (mediaIdx != -1) {
      try {
        await Supabase.instance.client
          .from('shop_media')
          .update({
            'comment': comment,
            'visibility': visibility,
          })
          .eq('id', id);
      } catch (e) {
        debugPrint('Error updating media comment: $e');
        _shopMedia[mediaIdx] = tempMedia;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<ShopMedia> addMedia(ShopMedia media) async {
    try {
      final response = await Supabase.instance.client
        .from('shop_media')
        .insert({
          'shop_id': media.shopId,
          'user_id': media.userId,
          'drink_id': media.drinkId,
          'image_path': media.imagePath,
          'is_banner': media.isBanner,
          'visibility': media.visibility,
          'comment': media.comment,
        })
        .select()
        .single();

      final insertedMedia = ShopMedia.fromJson(response);
      return insertedMedia;
    } catch (e) {
      debugPrint('Error inserting media: $e');
      rethrow;
    }
  }

  Future<void> removeMedia(String id) async {
    final removedMedia = getById(id);
    if (removedMedia == null) return;

    final wasBanner = removedMedia.isBanner;
    final shopId = removedMedia.shopId;

    _shopMedia.removeWhere((d) => d.id == id);
    notifyListeners();

    try {
      await ImageUploaderHelper.deleteImage(removedMedia.imagePath);
    } catch (e) {
      debugPrint('Error deleting media from storage: $e');
      rethrow;
    }

    try {
      await Supabase.instance.client
        .from('shop_media')
        .delete()
        .eq('id', id);

      if (wasBanner) {
        final remaining = _shopMedia.where((m) => m.shopId == shopId).toList();
        if (remaining.isNotEmpty) {
          await setBanner(shopId, remaining.first.id);
        }
      }
    } catch (e) {
      debugPrint('Remove media failed: $e');
      _shopMedia.add(removedMedia);
      notifyListeners();
      rethrow;
    }
  }

  // removes local cache. DB deletion done from admin panel
  void removeCache(String id) async {
    _shopMedia.removeWhere((sm) => sm.id == id);
    notifyListeners();
  }

  Future<void> removeAllMediaForShop(String shopId) async {
    final medias = getByShop(shopId);

    // Delete each image from storage (media-uploads and thumbs)
    await Future.wait(medias.map((media) async {
      if (media.imagePath.isNotEmpty) {
        try {
          await ImageUploaderHelper.deleteImage(media.imagePath);
        } catch (e) {
          debugPrint('Failed to delete image from storage: $e');
        }
      }
    }));

    _shopMedia.removeWhere((m) => m.shopId == shopId);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('shop_media')
        .delete()
        .eq('shop_id', shopId);
    } catch (e) {
      debugPrint('Error deleting shop_media from DB: $e');
      rethrow;
    }
  }

  void reset() {
    _shopMedia.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await RetryHelper.retry(() => supabase
        .from('shop_media')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
      );

      final pendings = _shopMedia.where((m) => m.isPending == true).toList();
      _shopMedia
        ..clear()
        ..addAll(
          response.map<ShopMedia>((json) => ShopMedia.fromJson(json))
        )
        ..addAll(pendings);

      notifyListeners();
      debugPrint('Loaded ${all.length} shop medias');
    } catch (e) {
      if (!_hasError) {
        _hasError = true;
        notifyListeners();
      }
      debugPrint('Error loading shop media state: $e');
    }
  }
}
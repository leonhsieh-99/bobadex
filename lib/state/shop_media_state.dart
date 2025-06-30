import 'package:bobadex/models/shop_media.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopMediaState extends ChangeNotifier {
  final List<ShopMedia> _shopMedia = [];

  List<ShopMedia> get all => _shopMedia;

  ShopMedia? getById(String id) {
    return _shopMedia.firstWhereOrNull((m) => m.id == id);
  }

  List<ShopMedia> getByShop(String shopId) {
    return _shopMedia.where((m) => m.shopId == shopId).toList();
  }

  void addPendingMedia(ShopMedia pending) {
    _shopMedia.add(pending);
    notifyListeners();
    print('[DEBUG] _shopMedia after mutation:');
for (final m in _shopMedia) print('  id: ${m.id}, pending: ${m.isPending}, imagePath: ${m.imagePath}');

  }

void replacePendingMedia(String pendingId, ShopMedia realMedia) {
  print('Replacing $pendingId with ${realMedia.id}');
  final idx = _shopMedia.indexWhere((m) => m.id == pendingId);
  if (idx != -1) {
    _shopMedia[idx] = realMedia;
    notifyListeners();
  } else {
    print('replacePendingMedia failed: $pendingId not found!');
  }
}


  void removePendingMedia(String mediaId) {
    _shopMedia.removeWhere((m) => m.id == mediaId);
    notifyListeners();
    print('[DEBUG] _shopMedia after mutation:');
for (final m in _shopMedia) print('  id: ${m.id}, pending: ${m.isPending}, imagePath: ${m.imagePath}');

  }

  String? getBannerId(String shopId) {
    return _shopMedia.firstWhereOrNull((sm) => sm.isBanner == true && sm.shopId == shopId)?.id;
  }

  Future<void> setBanner(String shopId, String mediaId) async {
    print('start');
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
      print('updating');
      if (hadOldBanner && oldBannerId != mediaId) {
        await Supabase.instance.client
          .from('shop_media')
          .update({'is_banner': false})
          .eq('id', oldBannerId);
      }
      await Supabase.instance.client
        .from('shop_media')
        .update({'is_banner': true})
        .eq('id', mediaId);
      print('done');
    } catch (e) {
      // Rollback local state if server update fails
      if (hadOldBanner) _shopMedia[oldIndex].isBanner = true;
      _shopMedia[newIndex].isBanner = false;
      notifyListeners();
      debugPrint('Error updating banner: $e');
      rethrow;
    }
  }

  Future<ShopMedia> addMedia(ShopMedia media) async {
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
  }

  Future<void> removeMedia(String id) async {
    final removedMedia = getById(id);
    if (removedMedia == null) return;

    _shopMedia.removeWhere((d) => d.id == id);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('shop_media')
        .delete()
        .eq('id', id);
    } catch (e) {
      debugPrint('Remove failed: $e');
      _shopMedia.add(removedMedia);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
      .from('shop_media')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id);

    final pendings = _shopMedia.where((m) => m.isPending == true).toList();
    _shopMedia
      ..clear()
      ..addAll(
        response.map<ShopMedia>((json) => ShopMedia.fromJson(json))
      )
      ..addAll(pendings);
    notifyListeners();
  }
}
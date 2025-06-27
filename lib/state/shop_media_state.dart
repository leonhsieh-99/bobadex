import 'package:bobadex/models/shop_media.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ShopMediaState extends ChangeNotifier {
  final List<ShopMedia> _shopMedia = [];

  List<ShopMedia> get all => _shopMedia;

  ShopMedia? getById(String id) {
    return _shopMedia.firstWhereOrNull((m) => m.id == id);
  }

  List<ShopMedia> getByShop(String shopId) {
    return _shopMedia.where((m) => m.shopId == shopId).toList();
  }

  Future<void> addMedia(ShopMedia media) async {
    final tempId = const Uuid().v4();
    final tempMedia = media.copyWith(id: tempId);
    _shopMedia.add(tempMedia);
    notifyListeners();

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

      final index = _shopMedia.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _shopMedia[index] = insertedMedia;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Insert failed: $e');
      _shopMedia.remove(media);
      notifyListeners();
      rethrow;
    }
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

    _shopMedia
      ..clear()
      ..addAll(
        response.map<ShopMedia>((json) => ShopMedia.fromJson(json))
      );
    notifyListeners();
  }
}
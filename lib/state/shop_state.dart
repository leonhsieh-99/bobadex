import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shop.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ShopState extends ChangeNotifier {
  final List<Shop> _shops = [];

  List<Shop> get all => _shops;

  Shop? getShop(String? id) {
    if (id == null) return null;
    return _shops.firstWhereOrNull((s) => s.id == id);
  }

  Shop? getShopByBrand(String? slug) {
    if (slug == null) return null;
    return _shops.firstWhereOrNull((s) => s.brandSlug == slug);
  }

  Future<Shop> add(Shop shop) async {
    String userId = Supabase.instance.client.auth.currentUser!.id;
    final tempId = const Uuid().v4();
    final tempShop = shop.copyWith(id: tempId);
    _shops.add(tempShop);
    notifyListeners();

    // save to db
    try {
      final response = await Supabase.instance.client
        .from('shops')
        .insert({
          'user_id': userId,
          'name': shop.name,
          'rating': shop.rating,
          'notes': shop.notes,
          'is_favorite': shop.isFavorite,
          'brand_slug': shop.brandSlug,
        })
        .select()
        .single();

      final insertedShop = Shop.fromJson(response);

      final index = _shops.indexWhere((s) => s.id == tempId);
      if (index != -1) {
        _shops[index] = insertedShop;
        notifyListeners();
        return insertedShop;
      }
      throw StateError('Error with temp id');
    } catch (e) {
      debugPrint('Insert failed: $e');
      _shops.removeWhere((s) => s.id == tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<Shop> update(Shop updated) async {
    final index = _shops.indexWhere((s) => s.id == updated.id);
    if (index == -1) {
      throw StateError('Shop not found in local state');
    }

    final originalShop = _shops[index];
    _shops[index] = updated;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('shops')
          .update({
            'name': updated.name,
            'rating': updated.rating,
            'is_favorite': updated.isFavorite,
            'brand_slug': updated.brandSlug,
            'pinned_drink_id': updated.pinnedDrinkId,
            'notes': updated.notes,
          })
          .eq('id', updated.id)
          .select()
          .single();

      final persistedShop = Shop.fromJson(response);
      _shops[index] = persistedShop;
      notifyListeners();
      return persistedShop;
    } catch (e) {
      debugPrint("Update failed: $e");
      _shops[index] = originalShop;
      notifyListeners();
      rethrow;
    }
  }


  Future<void> remove(String id) async {
    final temp = getShop(id);
    _shops.removeWhere((s) => s.id == id);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('shops')
        .delete().eq('id', id);
    } catch (e) {
      _shops.add(temp!);
      notifyListeners();
      rethrow;
    }
  }

  void replace(String oldId, Shop newShop) {
    final index = all.indexWhere((s) => s.id == oldId);
    if (index != -1) {
      all[index] = newShop;
    } else {
      all.add(newShop);
    }
    notifyListeners();
  }

  void reset() {
    _shops.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    final response = await supabase
      .from('shops')
      .select()
      .eq('user_id', userId);
    
    _shops
      ..clear()
      ..addAll(
        response.map<Shop>((json) => Shop.fromJson(json))
      );
      notifyListeners();
  }
}
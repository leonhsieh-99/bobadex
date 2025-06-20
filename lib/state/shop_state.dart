import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ShopState extends ChangeNotifier {
  List<Shop> _shops = [];

  List<Shop> get all => _shops;

  Shop? getShop(String? id) {
    if (id == null) return null;
    return _shops.firstWhereOrNull((s) => s.id == id);
  }

  void add(Shop shop) async {
    String userId = Supabase.instance.client.auth.currentUser!.id;
    _shops.add(shop);
    notifyListeners();

    // save to db
    try {
      final response = await Supabase.instance.client
        .from('shops')
        .insert({
          'user_id': userId,
          'name': shop.name,
          'image_path': shop.imagePath,
          'rating': shop.rating,
          'is_favorite': shop.isFavorite,
          'brand_slug': shop.brandSlug,
        }).select().single();
      
      // Update the shop with the ID from the database
      final index = _shops.indexWhere((s) => s.name == shop.name);
      if (index != -1) {
        _shops[index] = Shop.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      print('Insert failed: $e');
      _shops.remove(shop);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(Shop updated) async {
    final index = _shops.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      final temp = _shops[index];
      _shops[index] = updated;
      notifyListeners();
      try {
        await Supabase.instance.client
          .from('shops')
          .update({
            'name': updated.name,
            'image_path': updated.imagePath,
            'rating': updated.rating,
            'is_favorite': updated.isFavorite,
            'brand_slug': updated.brandSlug,
            'pinned_drink_id': updated.pinnedDrinkId,
            'notes': updated.notes,
          })
          .eq('id', updated.id);
      } catch (e) {
        print("Update failed: $e");
        _shops[index] = temp;
        notifyListeners();
        rethrow;
      }
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

    _shops = (response as List).map((json) => Shop.fromJson(json)).toList();
  }
}
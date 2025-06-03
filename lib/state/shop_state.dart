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


  void add(Shop shop) {
    _shops.add(shop);
    notifyListeners();
  }

  void update(Shop updated) {
    final index = _shops.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _shops[index] = updated;
      notifyListeners();
    }
  }

  void remove(String id) {
    _shops.removeWhere((s) => s.id == id);
    notifyListeners();
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
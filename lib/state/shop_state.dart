import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop.dart';
import 'package:flutter/material.dart';

class ShopState extends ChangeNotifier {
  List<Shop> _shops = [];

  List<Shop> get all => _shops;

  Shop getShop(String id) {
    return _shops.firstWhere((s) => s.id == id);
  }

  void addShop(Shop shop) {
    _shops.add(shop);
    notifyListeners();
  }

  void updateShop(Shop updated) {
    final index = _shops.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      _shops[index] = updated;
      notifyListeners();
    }
  }

  void removeShop(String id) {
    _shops.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void replaceShop(String oldId, Shop newShop) {
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
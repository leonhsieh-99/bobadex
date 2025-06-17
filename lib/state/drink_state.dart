import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink.dart';
import 'package:collection/collection.dart';

class DrinkState extends ChangeNotifier {
  List<Drink> drinks = [];
  
  List<Drink> get all => drinks;

  Drink? getDrink(String? id) {
    if (id == null) return null;
    return drinks.firstWhereOrNull((d) => d.id == id);
  }

  Future<void> update(Drink updated) async {
    final index = drinks.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      final temp = drinks[index];
      drinks[index] = updated;
      notifyListeners();
      try {
        await Supabase.instance.client
          .from('drinks')
          .update({
            'name': updated.name,
            'rating': updated.rating,
            'notes': updated.notes,
            'is_favorite': updated.isFavorite,
          })
          .eq('id', updated.id);
      } catch (e) {
        print('Update failed: $e');
        drinks[index] = temp;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> remove(String id) async {
    final temp = getDrink(id);
    drinks.removeWhere((d) => d.id == id);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('drinks')
        .delete()
        .eq('id', id);
    } catch (e) {
      print('Remove failed: $e');
      drinks.add(temp!);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> add(Drink drink, String shopId) async {
    String userId = Supabase.instance.client.auth.currentUser!.id;
    drinks.add(drink);
    notifyListeners();

    // save to db
    try {
      final response = await Supabase.instance.client
        .from('drinks')
        .insert({
          'shop_id': shopId,
          'user_id': userId,
          'name': drink.name,
          'rating': drink.rating,
          'is_favorite': drink.isFavorite,
        }).select().single();
      
      // Update the drink with the ID from the database
      final index = drinks.indexWhere((s) => s.name == drink.name);
      if (index != -1) {
        drinks[index] = Drink.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      print('Insert failed: $e');
      drinks.remove(drink);
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    drinks.clear();
    notifyListeners();
  }

  Map<String, List<Drink>> get drinksByShop {
    final map = <String, List<Drink>>{};
    for (final d in all) {
      map.putIfAbsent(d.shopId!, () => []).add(d);
    }
    return map;
  }


  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('drinks').select();
    final allDrinks = (response as List).map((json) => Drink.fromJson(json)).toList();
    drinks.clear();
    drinks.addAll(allDrinks);
    notifyListeners();
  }
}
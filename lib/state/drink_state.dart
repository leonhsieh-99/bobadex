import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink.dart';

class DrinkState extends ChangeNotifier {
  List<Drink> drinks = [];
  
  List<Drink> get all => drinks;

  void update(Drink updated) {
    final index = drinks.indexWhere((d) => d.id == updated.id);
    if (index != -1) drinks[index] = updated;
    notifyListeners();
  }

  void remove(String id) {
    drinks.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  void add(Drink drink) {
    drinks.add(drink);
    notifyListeners();
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
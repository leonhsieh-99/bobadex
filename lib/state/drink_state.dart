import 'package:bobadex/helpers/retry_helper.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/drink.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

class DrinkState extends ChangeNotifier {
  final List<Drink> _drinks = [];
  bool _hasError = false;
  
  List<Drink> get all => _drinks;
  bool get hasError => _hasError;

  Drink? getDrink(String? id) {
    if (id == null) return null;
    return _drinks.firstWhereOrNull((d) => d.id == id);
  }

  Future<void> update(Drink updated) async {
    final index = _drinks.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      final temp = _drinks[index];
      _drinks[index] = updated;
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
          .eq('id', updated.id!);
      } catch (e) {
        debugPrint('Update drink failed: $e');
        _drinks[index] = temp;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> remove(String id) async {
    final temp = getDrink(id);
    _drinks.removeWhere((d) => d.id == id);
    notifyListeners();

    try {
      await Supabase.instance.client
        .from('drinks')
        .delete()
        .eq('id', id);
    } catch (e) {
      debugPrint('Remove drink failed: $e');
      _drinks.add(temp!);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> add(Drink drink, String shopId) async {
    String userId = Supabase.instance.client.auth.currentUser!.id;
    final tempId = const Uuid().v4();
    final tempDrink = drink.copyWith(id: tempId);
    _drinks.add(tempDrink);
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
          'notes': drink.notes,
          'is_favorite': drink.isFavorite,
        }).select().single();
      
      // Update the drink with the ID from the database
      final insertedDrink = Drink.fromJson(response);

      final index = _drinks.indexWhere((d) => d.id == tempId);
      if (index != -1) {
        _drinks[index] = insertedDrink;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Insert drink failed: $e');
      _drinks.remove(tempDrink);
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    _drinks.clear();
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
    try {
      final supabase = Supabase.instance.client;
      final response = await RetryHelper.retry(() => supabase
        .from('drinks')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
      );

      _drinks
        ..clear()
        ..addAll(
          response.map<Drink>((json) => Drink.fromJson(json))
        );
      notifyListeners();
      debugPrint('Loaded ${all.length} drinks');
    } catch (e) {
      if (!_hasError) {
        _hasError = true;
        notifyListeners();
      }
      debugPrint('Error loading drinks: $e');
    }
  }
}
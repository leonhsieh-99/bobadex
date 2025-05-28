import 'drink.dart';

class DrinkCache {
  static final _drinks = <Drink>[];

  static void set(List<Drink> drinks) {
    _drinks.clear();
    _drinks.addAll(drinks);
  }
  
  static List<Drink> get all => _drinks;

  static void update(Drink updated) {
    final index = _drinks.indexWhere((d) => d.id == updated.id);
    if (index != -1) _drinks[index] = updated;
  }

  static void remove(String id) {
    _drinks.removeWhere((d) => d.id == id);
  }

  static void add(Drink drink) {
    _drinks.add(drink);
  }
}
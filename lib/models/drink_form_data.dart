import 'drink.dart';

class DrinkFormData {
  final String name;
  final double rating;
  final String? notes;

  DrinkFormData({
    required this.name,
    required this.rating,
    this.notes,
  });

  Map<String, dynamic> toInsertJson({
    required String shopId,
  }) {
    return {
      'shop_id': shopId,
      'name': name,
      'rating': rating,
      'notes': notes,
    };
  }

  Drink toDrink({String? shopId, String? id}) {
    return Drink(
      id: id,
      shopId: shopId,
      name: name,
      rating: rating,
      notes: notes,
    );
  }
}

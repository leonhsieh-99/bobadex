import 'drink.dart';

class DrinkFormData {
  final String name;
  final double rating;
  final String? notes;
  final bool? isFavorite;

  DrinkFormData({
    required this.name,
    required this.rating,
    this.notes,
    this.isFavorite,
  });

  Map<String, dynamic> toInsertJson({
    required String shopId,
  }) {
    return {
      'shop_id': shopId,
      'name': name,
      'rating': rating,
      'notes': notes,
      'is_favorite': isFavorite ?? false,
    };
  }

  Drink toDrink({String? shopId, String? id}) {
    return Drink(
      id: id,
      shopId: shopId,
      name: name,
      rating: rating,
      notes: notes,
      isFavorite: isFavorite ?? false,
    );
  }
}

import 'drink.dart';

class DrinkFormData {
  final String name;
  final double rating;

  DrinkFormData({
    required this.name,
    required this.rating,
  });

  Map<String, dynamic> toInsertJson({
    required String shopId,
  }) {
    return {
      'shop_id': shopId,
      'name': name,
      'rating': rating,
    };
  }

  Drink toDrink({String? shopId, String? id}) {
    return Drink(
      id: id,
      shopId: shopId,
      name: name,
      rating: rating,
    );
  }
}

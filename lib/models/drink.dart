class Drink {
  final String? id;
  final String? shopId;
  final String name;
  final double rating;
  final String? notes;

  Drink({
    this.id,
    this.shopId,
    required this.name,
    required this.rating,
    this.notes,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      shopId: json['shop_id'],
      name: json['name'],
      rating: (json['rating'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'rating': rating,
      'notes': notes,
    };
  }
}

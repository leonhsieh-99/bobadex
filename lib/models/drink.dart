import '../helpers/sortable_entry.dart';

class Drink extends SortableEntry {
  final String? id;
  final String? shopId;
  final String _name;
  final double _rating;
  final String? notes;
  final bool _isFavorite;

  @override
  String get name => _name;

  @override
  double get rating => _rating;

  @override
  bool get isFavorite => _isFavorite;

  Drink({
    this.id,
    this.shopId,
    required String name,
    required rating,
    this.notes,
    required bool isFavorite,
  }) : _name = name,
       _rating = rating,
       _isFavorite = isFavorite;

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'],
      shopId: json['shop_id'],
      name: json['name'],
      rating: (json['rating'] ?? 0).toDouble(),
      isFavorite: json['is_favorite'],
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
      'is_favorite': isFavorite,
    };
  }

  Drink copyWith({
    String? name,
    double? rating,
    String? notes,
    bool? isFavorite,
  }) {
    return Drink(
      id: id,
      shopId: shopId,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

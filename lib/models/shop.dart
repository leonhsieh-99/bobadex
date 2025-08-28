import 'drink.dart';
import '../helpers/sortable_entry.dart';

class Shop extends SortableEntry {
  final String? id;
  final String userId;
  String _name;
  double _rating;
  bool _isFavorite;
  String? notes;
  String? pinnedDrinkId;
  final DateTime? _createdAt;
  final String? placeId; // future use maybe
  final String? brandSlug;

  @override
  String get name => _name;

  set name(String val) => _name = val;

  @override
  double get rating => _rating;

  set rating(double val) => _rating = val;

  @override
  bool get isFavorite => _isFavorite;

  @override
  DateTime get createdAt => _createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  set isFavorite(bool val) => _isFavorite = val;

  Shop({
    this.id,
    required this.userId,
    required String name,
    required double rating,
    bool isFavorite = false,
    this.notes,
    this.pinnedDrinkId,
    DateTime? createdAt,
    this.placeId,
    this.brandSlug,
  }) :  _name = name,
        _rating = rating,
        _isFavorite = isFavorite,
        _createdAt = createdAt;

  Shop copyWith({
    String? id,
    String? userId,
    String? name,
    double? rating,
    String? imagePath,
    bool? isFavorite,
    String? notes,
    List<Drink>? drinks,
    String? pinnedDrinkId,
    DateTime? createdAt,
    String? placeId,
    String? brandSlug,
  }) {
    return Shop(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      pinnedDrinkId: pinnedDrinkId == '' ? null : pinnedDrinkId ?? this.pinnedDrinkId,
      createdAt: createdAt,
      placeId: placeId ?? this.placeId,
      brandSlug: brandSlug ?? this.brandSlug,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      notes: json['notes'] as String?,
      isFavorite: json['is_favorite'] ?? false,
      pinnedDrinkId: json['pinned_drink_id'] as String?,
      createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
      placeId: json['place_id'],
      brandSlug: json['brand_slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'rating': rating,
      'notes': notes,
      'is_favorite': isFavorite,
      'pinned_drink_id': pinnedDrinkId,
      'place_id': placeId,
      'brand_slug': brandSlug,
    };
  }
}
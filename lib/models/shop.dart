import 'package:supabase_flutter/supabase_flutter.dart';
import 'drink.dart';
import '../helpers/sortable_entry.dart';

class Shop extends SortableEntry {
  final String? id;
  String _name;
  double _rating;
  String? imagePath;  // raw Supabase path
  bool _isFavorite;
  final List<Drink>? drinks;
  final String? placeId; // future use maybe
  final String? brandSlug; // future use maybe

  @override
  String get name => _name;

  set name(String val) => _name = val;

  @override
  double get rating => _rating;

  set rating(double val) => _rating = val;

  @override
  bool get isFavorite => _isFavorite;

  set isFavorite(bool val) => _isFavorite = val;

  String get imageUrl => imagePath != null && imagePath!.isNotEmpty
    ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl(imagePath!.trim())
    : '';

  String get thumbUrl => imagePath != null && imagePath!.isNotEmpty
    ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl('thumbs/$imagePath'.trim())
    : '';

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  Shop({
    this.id,
    required String name,
    required double rating,
    this.imagePath,
    bool isFavorite = false,
    this.drinks = const [],
    this.placeId,
    this.brandSlug,
  }) :  _name = name,
        _rating = rating,
        _isFavorite = isFavorite;

  Shop copyWith({
    String? name,
    double? rating,
    bool? isFavorite,
    String? imagePath,
    List<Drink>? drinks,
    String? placeId,
    String? brandSlug,
  }) {
    return Shop(
      id: id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      imagePath: imagePath ?? this.imagePath,
      isFavorite: isFavorite ?? this.isFavorite,
      drinks: drinks ?? this.drinks,
      placeId: placeId ?? this.placeId,
      brandSlug: brandSlug ?? this.brandSlug,
    );
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imagePath: json['image_path'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
      drinks: [],
      placeId: json['place_id'],
      brandSlug: json['brand_slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'rating': rating,
      'is_favorite': isFavorite,
      'place_id': placeId,
      'brand_slug': brandSlug,
    };
  }
}

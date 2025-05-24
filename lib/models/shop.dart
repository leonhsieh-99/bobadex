import 'package:supabase_flutter/supabase_flutter.dart';
import 'drink.dart';
import '../helpers/sortable_entry.dart';

class Shop extends SortableEntry {
  final String? id;
  final String _name;
  final double _rating;
  final String? imagePath;  // raw Supabase path
  final String? imageUrl;     // signed display URL
  final bool _isFavorite;
  final DateTime? _urlExpiryTime;
  final List<Drink> drinks;
  final String? placeId; // future use maybe
  final String? brandSlug; // future use maybe
  static final Map<String, _CachedUrl> _urlCache = {};

  @override
  String get name => _name;

  @override
  double get rating => _rating;

  @override
  bool get isFavorite => _isFavorite;

  Shop({
    this.id,
    required String name,
    required double rating,
    this.imagePath,
    this.imageUrl,
    bool isFavorite = false,
    DateTime? urlExpiryTime,
    required this.drinks,
    this.placeId,
    this.brandSlug,
  }) : _urlExpiryTime = urlExpiryTime,
        _name = name,
        _rating = rating,
        _isFavorite = isFavorite;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imagePath: json['image_path'] ?? '',
      imageUrl: '', // placeholder, use fromJsonWithSignedUrl instead
      isFavorite: json['is_favorite'] ?? false,
      drinks: [],
      placeId: json['place_id'],
      brandSlug: json['brand_slug'],
    );
  }

  static Future<Shop> fromJsonWithSignedUrl(Map<String, dynamic> json) async {
    final path = json['image_path'] as String?;
    String imageUrl = '';
    DateTime? urlExpiryTime;

    if (path != null && path.isNotEmpty) {
      try {
        final cachedUrl = _urlCache[path];
        if (cachedUrl != null && !cachedUrl.isExpired) {
          imageUrl = cachedUrl.url;
          urlExpiryTime = cachedUrl.expiryTime;
        } else {
          final signed = await Supabase.instance.client.storage
            .from('media-uploads')
            .createSignedUrl(path, 3600);
          imageUrl = signed;
          urlExpiryTime = DateTime.now().add(const Duration(hours: 1));
          _urlCache[path] = _CachedUrl(url: imageUrl, expiryTime: urlExpiryTime);
        }
      } catch (e) {
        print('❌ Failed to sign URL: $e');
      }
    }

    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imagePath: path ?? '',
      imageUrl: imageUrl,
      isFavorite: json['is_favorite'] ?? false,
      urlExpiryTime: urlExpiryTime,
      drinks: [],
    );
  }

  Future<String> getImageUrl() async {
    final path = imagePath;
    if (_urlExpiryTime == null || DateTime.now().isAfter(_urlExpiryTime)) {
      try {
        final signed = await Supabase.instance.client.storage
          .from('media-uploads')
          .createSignedUrl(path!, 3600);

        _urlCache[path] = _CachedUrl(
          url: signed,
          expiryTime: DateTime.now().add(const Duration(hours: 1)),
        );

        return signed;
      } catch (e) {
        print('❌ Failed to refresh URL: $e');
        return imageUrl!; // fallback
      }
    }
    return imageUrl!;
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

class _CachedUrl {
  final String url;
  final DateTime expiryTime;

  _CachedUrl({required this.url, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

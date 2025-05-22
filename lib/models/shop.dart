import 'package:supabase_flutter/supabase_flutter.dart';
import 'drink.dart';

class Shop {
  final String? id;
  final String name;
  final double rating;
  final String? imagePath;  // raw Supabase path
  final String? imageUrl;     // signed display URL
  final bool isFavorite;
  final DateTime? _urlExpiryTime;
  final List<Drink> drinks;

  static final Map<String, _CachedUrl> _urlCache = {};

  Shop({
    this.id,
    required this.name,
    required this.rating,
    this.imagePath,
    this.imageUrl,
    this.isFavorite = false,
    DateTime? urlExpiryTime,
    required this.drinks,
  }) : _urlExpiryTime = urlExpiryTime;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'],
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imagePath: json['image_path'] ?? '',
      imageUrl: '', // placeholder, use fromJsonWithSignedUrl instead
      isFavorite: json['is_favorite'] ?? false,
      drinks: [],
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
    };
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiryTime;

  _CachedUrl({required this.url, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

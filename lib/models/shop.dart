import 'package:supabase_flutter/supabase_flutter.dart';

class Shop {
  final String? id;
  final String name;
  final double rating;
  final String imageUrl;
  final bool isFavorite;
  final DateTime? _urlExpiryTime;

  // Cache for signed URLs
  static final Map<String, _CachedUrl> _urlCache = {};

  Shop({
    this.id,
    required this.name,
    required this.rating,
    required this.imageUrl,
    this.isFavorite = false,
    DateTime? urlExpiryTime,
  }) : _urlExpiryTime = urlExpiryTime;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  static Future<Shop> fromJsonWithSignedUrl(Map<String, dynamic> json) async {
    final path = json['image_url'] as String?;
    String imageUrl = '';
    DateTime? urlExpiryTime;

    if (path != null && path.isNotEmpty) {
      try {
        // Check cache first
        final cachedUrl = _urlCache[path];
        if (cachedUrl != null && !cachedUrl.isExpired) {
          imageUrl = cachedUrl.url;
          urlExpiryTime = cachedUrl.expiryTime;
        } else {
          // Get new signed URL
          final signed = await Supabase.instance.client.storage
            .from('shop-images')
            .createSignedUrl(path, 3600);
          imageUrl = signed;
          urlExpiryTime = DateTime.now().add(const Duration(hours: 1));
          
          // Update cache
          _urlCache[path] = _CachedUrl(
            url: imageUrl,
            expiryTime: urlExpiryTime!,
          );
        }
      } catch (e) {
        print('❌ Failed to sign URL: $e');
      }
    }

    return Shop(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unnamed',
      rating: (json['rating'] ?? 0).toDouble(),
      imageUrl: imageUrl,
      isFavorite: json['is_favorite'] ?? false,
      urlExpiryTime: urlExpiryTime,
    );
  }

  // Method to refresh URL if needed
  Future<String> getImageUrl() async {
    if (_urlExpiryTime == null || DateTime.now().isAfter(_urlExpiryTime!)) {
      try {
        final path = imageUrl.split('/').last; // Get the filename from the URL
        final signed = await Supabase.instance.client.storage
          .from('shop-images')
          .createSignedUrl('public/$path', 3600);
        
        // Update cache
        _urlCache['public/$path'] = _CachedUrl(
          url: signed,
          expiryTime: DateTime.now().add(const Duration(hours: 1)),
        );
        
        return signed;
      } catch (e) {
        print('❌ Failed to refresh URL: $e');
        return imageUrl; // Return old URL if refresh fails
      }
    }
    return imageUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'rating': rating,
      'is_favorite': isFavorite,
    };
  }
}

// Helper class for URL caching
class _CachedUrl {
  final String url;
  final DateTime expiryTime;

  _CachedUrl({
    required this.url,
    required this.expiryTime,
  });

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}


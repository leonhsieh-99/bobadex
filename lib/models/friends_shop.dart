import 'package:bobadex/models/drink.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsShop {
  final String brandSlug;
  final String name;
  final double avgRating;
  final List<String> gallery;
  final String iconPath;
  final String mostDrinksUser;
  final Map<String, FriendShopInfo> friendsInfo;

  FriendsShop({
    required this.brandSlug,
    required this.name,
    required this.avgRating,
    this.gallery = const [],
    required this.iconPath,
    required this.mostDrinksUser,
    this.friendsInfo = const {},
  });

  factory FriendsShop.fromJson(Map<String, dynamic> json) => FriendsShop(
    brandSlug: json['brand_slug'] as String,
    name: json['display'] as String,
    avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
    gallery: (json['gallery'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .where((s) => s.trim().isNotEmpty)
        .toList(),
    iconPath: json['icon_path'] as String? ?? '',
    mostDrinksUser: json['most_drinks_user_id'] ?? '',
    friendsInfo: (json['friends_info'] as Map<String, dynamic>)
      .map((key, value) => MapEntry(key, FriendShopInfo.fromJson(value))),
  );
}

class FriendShopInfo {
  final double rating;
  final String? note;
  final bool isFavorite;
  final List<Drink> top5Drinks;
  final String? filePath;

  FriendShopInfo({
    required this.rating,
    this.note,
    this.isFavorite = false,
    required this.top5Drinks,
    this.filePath,
  });

  String get thumbUrl => filePath != null && filePath!.isNotEmpty
    ? Supabase.instance.client.storage
        .from('media-uploads')
        .getPublicUrl('thumbs/${filePath!.trim()}')
    : '';


  factory FriendShopInfo.fromJson(Map<String, dynamic> json) => FriendShopInfo(
    rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    note: json['note'] as String?,
    isFavorite: json['is_favorite'] as bool,
    top5Drinks: (json['top_5_drinks'] as List<dynamic>? ?? [])
        .map((e) => Drink.fromJson(Map<String, dynamic>.from(e))).toList(),
    filePath: json['file_path'],
  );
}
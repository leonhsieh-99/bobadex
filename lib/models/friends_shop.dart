import 'package:bobadex/models/drink.dart';

class FriendsShop {
  final String brandSlug;
  final String name;
  final double avgRating;
  final String? iconPath;
  final String mostDrinksUser;
  final Map<String, FriendShopInfo> friendsInfo;

  FriendsShop({
    required this.brandSlug,
    required this.name,
    required this.avgRating,
    required this.iconPath,
    required this.mostDrinksUser,
    this.friendsInfo = const {},
  });

  factory FriendsShop.fromJson(Map<String, dynamic> json) {
    final rawFriends = (json['friends_info'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    return FriendsShop(
      brandSlug: (json['brand_slug'] as String?) ?? '',
      name: (json['display'] as String?) ?? 'Unknown',
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      iconPath: json['icon_path'] as String?,
      mostDrinksUser: (json['most_drinks_user_id'] as String?) ?? '',
      friendsInfo: rawFriends.map((userId, value) {
        final v = (value as Map).cast<String, dynamic>();
        return MapEntry(userId, FriendShopInfo.fromJson(v, idFallback: userId));
      }),
    );
  }
}

class FriendShopInfo {
  final String id;
  final double rating;
  final String? note;
  final bool isFavorite;
  final List<Drink> top3Drinks;
  final String? filePath;
  final int drinksTried;
  final int? galleryCount;

  FriendShopInfo({
    required this.id,
    required this.rating,
    this.note,
    this.isFavorite = false,
    required this.top3Drinks,
    this.filePath,
    required this.drinksTried,
    this.galleryCount,
  });

  factory FriendShopInfo.fromJson(
    Map<String, dynamic> json, {
    required String idFallback,
  }) {
    return FriendShopInfo(
      id: (json['id'] as String?) ?? idFallback, 
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      note: json['note'] as String?,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
      top3Drinks: (json['top_3_drinks'] as List<dynamic>? ?? const [])
          .map((e) => Drink.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      filePath: json['file_path'] as String?,
      drinksTried: (json['drinks_tried'] as int?) ?? 0,
      galleryCount: json['gallery_count'] as int?,
    );
  }
}

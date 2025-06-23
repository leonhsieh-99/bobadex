class FriendsShop {
  final String brandSlug;
  final String name;
  final double avgRating;
  final List<String> gallery;
  final String iconPath;
  final Map<String, double> friendsRatings;

  FriendsShop({
    required this.brandSlug,
    required this.name,
    required this.avgRating,
    this.gallery = const [],
    required this.iconPath,
    this.friendsRatings = const {},
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
    friendsRatings: (json['friends_ratings'] != null && json['friends_ratings'] is Map
        ? (json['friends_ratings'] as Map<String, dynamic>)
        : <String, dynamic>{})
      .map((key, value) => MapEntry(key, (value as num).toDouble())),
  );

  Map<String, dynamic> toJson() => {
    'brand_slug': brandSlug,
    'name': name,
    'avg_rating': avgRating,
    'gallery': gallery,
    'icon_path': iconPath,
    'friends_ratings': friendsRatings,
  };
}

class TeaRoomComment {
  final String id;
  final String userId;
  final String displayName;
  final String text;
  final DateTime createdAt;

  TeaRoomComment({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  factory TeaRoomComment.fromJson(Map<String, dynamic> json) => TeaRoomComment(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'display_name': displayName,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };
}

class TeaRoomShop {
  final String brandSlug;
  final String name;
  final double avgRating;
  final List<String> gallery;
  final String iconPath;
  final Map<String, double> memberRatings;
  final List<TeaRoomComment>? comments;

  TeaRoomShop({
    required this.brandSlug,
    required this.name,
    required this.avgRating,
    this.gallery = const [],
    required this.iconPath,
    this.memberRatings = const {},
    this.comments, // optional for MVP
  });

  factory TeaRoomShop.fromJson(Map<String, dynamic> json) => TeaRoomShop(
        brandSlug: json['brand_slug'] as String,
        name: json['display'] as String,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
        gallery: (json['gallery'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
        iconPath: json['icon_path'] as String? ?? '',
        memberRatings: (json['member_ratings'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, (value as num).toDouble())),
        comments: (json['comments'] as List<dynamic>?)
            ?.map((c) => TeaRoomComment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'brand_slug': brandSlug,
        'name': name,
        'avg_rating': avgRating,
        'gallery': gallery,
        'icon_path': iconPath,
        'member_ratings': memberRatings,
        if (comments != null) 'comments': comments!.map((c) => c.toJson()).toList(),
      };
}

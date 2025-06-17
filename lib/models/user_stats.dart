import 'user.dart';

class UserStats extends User {
  final int shopCount;

  UserStats({
    required super.id,
    required super.displayName,
    required super.username,
    super.profileImagePath,
    super.bio,
    required this.shopCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'],
      displayName: json['display_name'],
      username: json['username'],
      profileImagePath: json['profile_image_path'] ?? '',
      bio: json['bio'] ?? '',
      shopCount: json['shop_count'],
    );
  }
}
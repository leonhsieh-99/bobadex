import 'user.dart';

class UserStats extends User {
  final int shopCount;
  final int metricValue;
  final int rank;

  UserStats({
    required super.id,
    required super.displayName,
    required super.username,
    super.profileImagePath,
    super.bio,
    required this.shopCount,
    required this.metricValue,
    required this.rank,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final shopCount = _asInt(json['shop_count']);
    return UserStats(
      id: json['id'],
      displayName: json['display_name'] ?? '',
      username: json['username'] ?? '',
      profileImagePath: json['profile_image_path'] ?? '',
      bio: json['bio'] ?? '',
      shopCount: shopCount,
      metricValue: json['metric_value'] == null
          ? shopCount
          : _asInt(json['metric_value']),
      rank: _asInt(json['rank']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

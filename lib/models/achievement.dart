import 'dart:convert';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconPath;
  final int displayOrder;
  final bool isHidden;
  final Map<String, dynamic> dependsOn;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.displayOrder,
    this.isHidden = false,
    required this.dependsOn,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final dependsOnRaw = json['depends_on'];
    Map<String, dynamic> dependsOn;
    if (dependsOnRaw == null) {
      dependsOn = {};
    } else if (dependsOnRaw is Map<String, dynamic>) {
      dependsOn = dependsOnRaw;
    } else if (dependsOnRaw is String && dependsOnRaw.isNotEmpty) {
      dependsOn = jsonDecode(dependsOnRaw) as Map<String, dynamic>;
    } else {
      dependsOn = {};
    }

    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      iconPath: json['icon_path'],
      displayOrder: json['display_order'] ?? 0,
      isHidden: json['is_hidden'] ?? false,
      dependsOn: dependsOn,
    );
  }
}


class UserAchievement {
  final String achievementId;
  bool unlocked;
  final int progress;
  bool pinned;

  UserAchievement({
    required this.achievementId,
    required this.unlocked,
    required this.progress,
    required this.pinned,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievementId: json['achievement_id'],
      unlocked: json['unlocked'] ?? false,
      progress: json['progress'] ?? 0,
      pinned: json['pinned'] ?? false,
    );
  }
}

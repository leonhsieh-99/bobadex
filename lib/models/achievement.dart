class Achievement {
  final int id;
  final String name;
  final String description;
  final String iconPath;
  final int displayOrder;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.displayOrder,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      iconPath: json['icon_path'] ?? '',
      displayOrder: json['display_order'] ?? 0,
    );
  }
}

class UserAchievement {
  final int achievementId;
  final bool unlocked;
  final int progress;
  final bool pinned;

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

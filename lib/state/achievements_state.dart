import 'package:bobadex/models/achievement.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsState extends ChangeNotifier {
  final List<Achievement> _achievements = [];
  final List<UserAchievement> _userAchievements = [];
  final Map<int, UserAchievement> _progressMap = {};

  List<Achievement> get achievements => _achievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  Map<int, UserAchievement> get progressMap => _progressMap;

  String getBadgeAssetPath(String? path) {
    if (path == null || path.isEmpty || path == '/icons/' || path == 'null') {
      return 'lib/assets/default_badge.png';
    }
    return path.startsWith('/') ? 'lib/assets$path' : path;
  }

  void reset() {
    _achievements.clear();
    _userAchievements.clear();
    _progressMap.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    // Clear existing data to avoid duplicates if reloading
    _achievements.clear();
    _userAchievements.clear();
    _progressMap.clear();

    final supabase = Supabase.instance.client;

    final achievements = await supabase
      .from('achievements')
      .select()
      .order('display_order');
    final userAchievements = await supabase
      .from('user_achievements')
      .select()
      .eq('user_id', supabase.auth.currentUser!.id);

    _achievements.addAll(
      (achievements as List).map((json) => Achievement.fromJson(json)).toList().reversed
    );
    _userAchievements.addAll(
      (userAchievements as List).map((json) => UserAchievement.fromJson(json))
    );
    for (var ua in _userAchievements) {
      _progressMap[ua.achievementId] = ua;
    }
    notifyListeners();
  }
}

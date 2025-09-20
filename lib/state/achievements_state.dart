import 'dart:async';
import 'package:bobadex/helpers/retry_helper.dart';
import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsState extends ChangeNotifier {
  final List<Achievement> _achievements = [];
  final List<UserAchievement> _userAchievements = [];
  final Map<String, UserAchievement> _progressMap = {};
  final List<Achievement> _pendingAchievements = [];

  final StreamController<Achievement> _unlockedCtrl =
    StreamController<Achievement>.broadcast();

  bool _hasError = false;

  List<Achievement> get achievements => _achievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  Map<String, UserAchievement> get progressMap => _progressMap;
  Stream<Achievement> get unlockedAchievementsStream => _unlockedCtrl.stream;
  bool get hasError => _hasError;

  String normalizer(String name) {
    return name
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll(RegExp(r'\s+'), '');
  }

  void _emitUnlocked(Achievement a) {
    if (!_unlockedCtrl.isClosed) {
      _unlockedCtrl.add(a);
    } else {
      debugPrint('unlockedAchievements stream is closed; dropping ${a.name}');
    }
  }

  // Uses rpc to fetch achievement stats for drink-related achievements
  Future<DrinkCounts> fetchDrinkCounts() async {
    final supabase = Supabase.instance.client;
    final res = await supabase.rpc('drink_achievement_counts');
    if (res is Map<String, dynamic>) return DrinkCounts.fromMap(res);
    if (res is List && res.isNotEmpty && res.first is Map<String, dynamic>) {
      return DrinkCounts.fromMap(res.first as Map<String, dynamic>);
    }
    return DrinkCounts(total: 0, matcha: 0, notes: 0, maxInShop: 0);
  }

  String getBadgeAssetPath(String? path) {
    if (path == null || path.isEmpty || path == '/icons/' || path == 'null') {
      return 'lib/assets/default_badge.png';
    }
    return path.startsWith('/') ? 'lib/assets$path' : path;
  }

  List<Achievement> getAllType(String type) {
    return _achievements.where((a) => a.dependsOn['type'] == type).toList();
  }

  Future<void> setPinned(String achievementId) async {
    final ua = _progressMap[achievementId];
    if (ua?.unlocked == true) {
      final newPin = !ua!.pinned;
      ua.pinned = newPin;
      notifyListeners();
      try {
        await Supabase.instance.client
          .from('user_achievements')
          .update({'pinned': newPin})
          .eq('achievement_id', ua.achievementId)
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
      } catch (e) {
        debugPrint('Error updating pin: $e');
        ua.pinned = !newPin;
        notifyListeners();
        rethrow;
      }
    }
  }

  void queueAchievement(Achievement a) {
    _pendingAchievements.add(a);
    notifyListeners();
  }

  List<Achievement> consumeQueuedAchievements() {
    final achievements = List<Achievement>.from(_pendingAchievements);
    _pendingAchievements.clear();
    return achievements;
  }

  Future<void> checkAndUnlock(int count, int min, Achievement a) async {
    final alreadyUnlocked = _progressMap[a.id]?.unlocked == true;
    if (count >= min && !alreadyUnlocked) {
      final newAchievement = UserAchievement(achievementId: a.id, unlocked: true, progress: count, pinned: false);
      _progressMap[a.id] = newAchievement;
      notifyListeners();
      _emitUnlocked(a);
      try {
        await Supabase.instance.client
          .from('user_achievements')
          .insert({
            'achievement_id': a.id,
            'user_id': Supabase.instance.client.auth.currentUser!.id,
            'unlocked': true,
            'unlocked_at': DateTime.now().toIso8601String(),
            'pinned': false,
            'progress': count,
          });
      } catch (e) {
        debugPrint('Error inserting achievement: $e');
        _progressMap.remove(a.id);
        notifyListeners();
        rethrow;
      }
      await checkAndUpdateAllAchievement();
    }
  }

  Future<void> checkAndUnlockShopAchievement(ShopState shopState) async {
    for (final a in getAllType('shop_count')) {
      int count = shopState.shopsForCurrentUser().length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockDrinkAchievement(DrinkState drinkState) async {
    final c = await fetchDrinkCounts();

    // total drink count achievements
    for (final a in getAllType('drink_count')) {
      final min = a.dependsOn['min'] as int;
      await checkAndUnlock(c.total, min, a);
    }

    // matcha count for performative achievement
    final a = _achievements.firstWhere((x) => x.dependsOn['type'] == 'matcha_drink_count');
    await checkAndUnlock(c.matcha, a.dependsOn['min'] as int, a);

    notifyListeners();
  }

  Future<void> checkAndUnlockFriendAchievement(FriendState friendState) async {
    for (final a in getAllType('friend_count')) {
      int count = friendState.friends.length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockNotesAchievement(DrinkState drinkState) async {
    final c = await fetchDrinkCounts();
    for (final a in getAllType('drink_notes_count')) {
      await checkAndUnlock(c.notes, a.dependsOn['min'] as int, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockMaxDrinksShopAchievement(DrinkState drinkState) async {
    final c = await fetchDrinkCounts();
    for (final a in getAllType('max_drinks_single_shop')) {
      await checkAndUnlock(c.maxInShop, a.dependsOn['min'] as int, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockMediaUploadAchievement() async {
    final count = await _mediaUploadCount();
    for (final a in getAllType('media_upload_count')) {
      final int min = a.dependsOn['min'] as int;
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockBrandAchievement(ShopState shopState) async {
    for (final a in getAllType('visited_brands')) {
      final brands = a.dependsOn['brands'];
      int count = 0;
      final allShops = shopState.shopsForCurrentUser().map((s) => normalizer(s.name));
      for (var brand in brands) {
        if (allShops.contains(normalizer(brand))) {
          count += 1;
        }
      }
      int min = brands.length;
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUpdateAllAchievement() async {
    final a = _achievements.firstWhere((a) => a.dependsOn['type'] == 'all_achievements');
    // Only count regular achievements as unlocked (not 'all_achievements' itself)
    final regularAchievements = _achievements.where((ach) => ach.dependsOn['type'] != 'all_achievements').toList();
    final unlockedCount = _progressMap.values
        .where((ua) => ua.unlocked && regularAchievements.any((ach) => ach.id == ua.achievementId))
        .length;
    final shouldUnlock = unlockedCount == regularAchievements.length;
    final alreadyUnlocked = _progressMap[a.id]?.unlocked == true;

    if (shouldUnlock && !alreadyUnlocked) {
      final newAchievement = UserAchievement(
        achievementId: a.id,
        unlocked: true,
        progress: unlockedCount,
        pinned: false,
      );
      _progressMap[a.id] = newAchievement;
      notifyListeners();
      try {
        await Supabase.instance.client
          .from('user_achievements')
          .insert({
            'achievement_id': a.id,
            'user_id': Supabase.instance.client.auth.currentUser!.id,
            'unlocked': true,
            'unlocked_at': DateTime.now().toIso8601String(),
            'pinned': false,
            'progress': unlockedCount,
          });
      } catch (e) {
        debugPrint('Error inserting all achievement: $e');
        _progressMap.remove(a.id);
        notifyListeners();
        rethrow;
      }
    } else if (!shouldUnlock && alreadyUnlocked) {
      // uh
    }
  }

  void reset() {
    _achievements.clear();
    _userAchievements.clear();
    _progressMap.clear();
    _pendingAchievements.clear();
    _hasError = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (!_unlockedCtrl.isClosed) {
      _unlockedCtrl.close();
    }
    super.dispose();
  }

  Future<void> loadFromSupabase() async {
    try {
      _achievements.clear();
      _userAchievements.clear();
      _progressMap.clear();

      final supabase = Supabase.instance.client;

      final achievements = await RetryHelper.retry(() => supabase
        .from('achievements')
        .select()
        .order('display_order')
      );
      final userAchievements = await RetryHelper.retry(() => supabase
        .from('user_achievements')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
      );

      _achievements.addAll(
        (achievements as List).map((json) => Achievement.fromJson(json)).toList().reversed
      );
      _userAchievements.addAll(
        (userAchievements as List).map((json) => UserAchievement.fromJson(json))
      );
      for (final ua in _userAchievements) {
        _progressMap[ua.achievementId] = ua;
      }
      _hasError = false;
      notifyListeners();
    } catch (e) {
      if (!_hasError) {
        _hasError = true;
        notifyListeners();
      }
      debugPrint('Error loading achievements state: $e');
    }
  }
}

// helper drink count class
class DrinkCounts {
  final int total, matcha, notes, maxInShop;
  DrinkCounts({required this.total, required this.matcha, required this.notes, required this.maxInShop});
  factory DrinkCounts.fromMap(Map<String, dynamic> m) => DrinkCounts(
    total: (m['total'] ?? 0) as int,
    matcha: (m['matcha'] ?? 0) as int,
    notes: (m['notes'] ?? 0) as int,
    maxInShop: (m['max_in_shop'] ?? 0) as int,
  );
}

// generic token count, uncomment if need to use in future
// Future<int> _countByToken(String token) async {
//   final supabase = Supabase.instance.client;
//   final res = await supabase.rpc('drink_count_by_name_token', params: {'token': token});
//   if (res is int) return res;
//   if (res is num) return res.toInt();
//   return 0;
// }

Future<int> _mediaUploadCount() async {
  final res = await Supabase.instance.client.rpc('media_upload_count');
  return (res as int?) ?? 0;
}
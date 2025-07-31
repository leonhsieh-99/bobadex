import 'dart:async';

import 'package:bobadex/helpers/retry_helper.dart';
import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsState extends ChangeNotifier {
  final List<Achievement> _achievements = [];
  final List<UserAchievement> _userAchievements = [];
  final Map<String, UserAchievement> _progressMap = {};
  final List<Achievement> _pendingAchievements = [];
  final _unlockedAchievementController = StreamController<Achievement>.broadcast();
  bool _hasError = false;

  List<Achievement> get achievements => _achievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  Map<String, UserAchievement> get progressMap => _progressMap;
  Stream<Achievement> get unlockedAchievementsStream => _unlockedAchievementController.stream;
  bool get hasError => _hasError;

  String normalizer(String name) {
    return name
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll(RegExp(r'\s+'), '');
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
      _unlockedAchievementController.add(a);
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
      int count = shopState.all.length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockDrinkAchievement(DrinkState drinkState) async {
    for (final a in getAllType('drink_count')) {
      int count = drinkState.all.length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    final a = _achievements.firstWhere((a) => a.dependsOn['type'] == 'matcha_drink_count');
    int count = drinkState.all.where((d) => d.name.toLowerCase().split(' ').contains('matcha')).length;
    int min = a.dependsOn['min'];
    await checkAndUnlock(count, min, a);
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
    for (final a in getAllType('drink_notes_count')) {
      int count = drinkState.all.where((d) => d.notes != null && d.notes!.isNotEmpty).length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockMaxDrinksShopAchievement(DrinkState drinkState) async {
    for (final a in getAllType('max_drinks_single_shop')) {
      final Map<String, int> drinkToShop = {};
      for (var drink in drinkState.all) {
        final shopId = drink.shopId;
        if (shopId != null) {
          drinkToShop[shopId] = (drinkToShop[shopId] ?? 0) + 1;
        }
      }
      int count = drinkToShop.values.isEmpty ? 0 : drinkToShop.values.reduce((a, b) => a > b ? a : b);
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockMediaUploadAchievement(ShopMediaState shopMediaState) async {
    for (final a in getAllType('media_upload_count')) {
      int count = shopMediaState.all.length;
      int min = a.dependsOn['min'];
      await checkAndUnlock(count, min, a);
    }
    notifyListeners();
  }

  Future<void> checkAndUnlockBrandAchievement(ShopState shopState) async {
    for (final a in getAllType('visited_brands')) {
      final brands = a.dependsOn['brands'];
      int count = 0;
      final allShops = shopState.all.map((s) => normalizer(s.name));
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
    _unlockedAchievementController.close();
    notifyListeners();
  }

  Future<void> loadFromSupabase() async {
    try {
      // Clear existing data to avoid duplicates if reloading
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
      for (var ua in _userAchievements) {
        _progressMap[ua.achievementId] = ua;
      }
      notifyListeners();
      debugPrint('Loaded ${achievements.length} achievements');
    } catch (e) {
      if (!_hasError) {
        _hasError = true;
        notifyListeners();
      }
      debugPrint('Error loading achievements state: $e');
    }
  }
}

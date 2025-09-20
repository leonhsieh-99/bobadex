import 'package:bobadex/config/constants.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AchievementsPage extends StatefulWidget {
  final String userId;

  const AchievementsPage({super.key, required this.userId});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  Future<_UiCounts>? _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
  }

  String _normalize(String s) =>
    s.toLowerCase().replaceAll('_', '').replaceAll(RegExp(r'\s+'), '');

  Future<_UiCounts> _loadCounts() async {
    final ach = context.read<AchievementsState>();
    final shopState = context.read<ShopState>();
    final friendState = context.read<FriendState>();

    // Drink-related via RPC
    final dc = await ach.fetchDrinkCounts();

    // Others via local states
    final shopCount = shopState.shopsForCurrentUser().length;
    final friendCount = friendState.friends.length;
    final mediaCount = await _mediaUploadCount();

    // visited brands
    final normalizedShopNames = shopState.shopsForCurrentUser().map((s) => _normalize(s.name)).toSet();

    // all achievements (unlocked count)
    final unlockedCount = ach.progressMap.values.where((ua) => ua.unlocked).length;
    final totalRegular = ach.achievements.where((a) => a.dependsOn['type'] != 'all_achievements').length;

    return _UiCounts(
      shopCount: shopCount,
      drinkTotal: dc.total,
      drinkNotes: dc.notes,
      drinkMatcha: dc.matcha,
      maxInSingleShop: dc.maxInShop,
      friendCount: friendCount,
      mediaCount: mediaCount,
      normalizedShopNames: normalizedShopNames,
      unlockedCount: unlockedCount,
      totalRegularAchievements: totalRegular,
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = context.watch<AchievementsState>();
    final achievements = achievementState.achievements;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: FutureBuilder<_UiCounts>(
        future: _countsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const _AchievementSkeletonList();
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load achievements. Pull back and re-open.',
                  textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) {
            return const _AchievementSkeletonList(itemCount: 8);
          }
          
          final counts = snap.data!;
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final a = achievements[index];
              final dep = a.dependsOn;
              int have = 0;
              int need = 0;

              switch (dep['type']) {
                case 'shop_count':
                  have = counts.shopCount;
                  need = dep['min'] as int;
                  break;

                case 'drink_count':
                  have = counts.drinkTotal;
                  need = dep['min'] as int;
                  break;

                case 'drink_notes_count':
                  have = counts.drinkNotes;
                  need = dep['min'] as int;
                  break;

                case 'friend_count':
                  have = counts.friendCount;
                  need = dep['min'] as int;
                  break;

                case 'max_drinks_single_shop':
                  have = counts.maxInSingleShop;
                  need = dep['min'] as int;
                  break;

                case 'media_upload_count':
                  have = counts.mediaCount;
                  need = dep['min'] as int;
                  break;

                case 'matcha_drink_count':
                  have = counts.drinkMatcha;
                  need = dep['min'] as int;
                  break;

                case 'visited_brands':
                  final brands = (dep['brands'] as List).cast<String>();
                  have = brands
                      .map(_normalize)
                      .where(counts.normalizedShopNames.contains)
                      .length;
                  need = brands.length;
                  break;

                case 'all_achievements':
                  have = counts.unlockedCount;
                  need = counts.totalRegularAchievements;
                  break;
              }

              if (have > need) have = need;

              const double iconSize = 40;
              const double avatarRadius = iconSize / 2;

              final locked = have < need && a.isHidden;

              return ListTile(
                leading: locked
                    ? Container(
                        width: iconSize,
                        height: iconSize,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Icon(Icons.question_mark, size: iconSize * 0.75),
                      )
                    : CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: (a.iconPath != null && a.iconPath!.isNotEmpty)
                            ? AssetImage(a.iconPath!)
                            : const AssetImage('lib/assets/badges/default_badge.png'),
                        backgroundColor: have == need ? Colors.amber : Constants.badgeBgColor,
                      ),
                title: Text(locked ? 'Hidden' : a.name),
                subtitle: Text(locked ? '? ? ?' : a.description),
                trailing: have == need
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : Text('$have/$need', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              );
            },
          );
        },
      ),
    );
  }
}

class _UiCounts {
  final int shopCount;
  final int drinkTotal;
  final int drinkNotes;
  final int drinkMatcha;
  final int maxInSingleShop;
  final int friendCount;
  final int mediaCount;
  final Set<String> normalizedShopNames;
  final int unlockedCount;
  final int totalRegularAchievements;

  _UiCounts({
    required this.shopCount,
    required this.drinkTotal,
    required this.drinkNotes,
    required this.drinkMatcha,
    required this.maxInSingleShop,
    required this.friendCount,
    required this.mediaCount,
    required this.normalizedShopNames,
    required this.unlockedCount,
    required this.totalRegularAchievements,
  });
}

class _AchievementSkeletonList extends StatelessWidget {
  final int itemCount;
  const _AchievementSkeletonList({this.itemCount = 15});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Right column of two lines
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 100, // shorter top line
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity, // longer bottom line
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<int> _mediaUploadCount() async {
  final res = await Supabase.instance.client.rpc('media_upload_count');
  return (res as int?) ?? 0;
}
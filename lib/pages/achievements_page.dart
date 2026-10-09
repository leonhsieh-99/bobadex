import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bobadex/ui/theme/boba_context.dart';

class AchievementsPage extends StatefulWidget {
  final String userId;
  final bool pinMode;

  const AchievementsPage({
    super.key,
    required this.userId,
    this.pinMode = false,
  });

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
    final normalizedShopNames = <String>{};
    for (final shop in shopState.shopsForCurrentUser()) {
      normalizedShopNames.add(_normalize(shop.name));
      final slug = shop.brandSlug;
      if (slug != null && slug.isNotEmpty) {
        normalizedShopNames.add(_normalize(slug));
      }
    }

    // all achievements (unlocked count)
    final unlockedCount = ach.progressMap.values
        .where((ua) => ua.unlocked)
        .length;
    final totalRegular = ach.achievements
        .where((a) => a.dependsOn['type'] != 'all_achievements')
        .length;

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
                child: Text(
                  'Failed to load achievements. Pull back and re-open.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const _AchievementSkeletonList(itemCount: 8);
          }

          final counts = snap.data!;
          final rows = <({Achievement a, int have, int need})>[];
          for (final a in achievements) {
            final dep = a.dependsOn;
            var have = 0;
            var need = 0;
            switch (dep['type']) {
              case 'shop_count':
                have = counts.shopCount;
                need = dep['min'] as int;
              case 'drink_count':
                have = counts.drinkTotal;
                need = dep['min'] as int;
              case 'drink_notes_count':
                have = counts.drinkNotes;
                need = dep['min'] as int;
              case 'friend_count':
                have = counts.friendCount;
                need = dep['min'] as int;
              case 'max_drinks_single_shop':
                have = counts.maxInSingleShop;
                need = dep['min'] as int;
              case 'media_upload_count':
                have = counts.mediaCount;
                need = dep['min'] as int;
              case 'matcha_drink_count':
                have = counts.drinkMatcha;
                need = dep['min'] as int;
              case 'visited_brands':
                final brands = (dep['brands'] as List).cast<String>();
                have = brands
                    .map(_normalize)
                    .where(counts.normalizedShopNames.contains)
                    .length;
                need = dep['match'] == 'any' ? 1 : brands.length;
              case 'all_achievements':
                have = counts.unlockedCount;
                need = counts.totalRegularAchievements;
            }
            if (have > need) have = need;
            rows.add((a: a, have: have, need: need));
          }

          final groups =
              <String, List<({Achievement a, int have, int need})>>{};
          for (final row in rows) {
            groups.putIfAbsent(_familyOf(row.a), () => []).add(row);
          }

          return ListView(
            children: [
              for (final entry in groups.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final row in entry.value)
                  _AchievementTile(row: row, pinMode: widget.pinMode),
              ],
            ],
          );
        },
      ),
    );
  }
}

String _familyOf(Achievement a) {
  // Group by unlock type so a series stays together, including its last tier.
  switch (a.dependsOn['type']) {
    case 'shop_count':
      return 'Boba Explorer';
    case 'drink_count':
      return 'Bobaholic';
    case 'drink_notes_count':
      return 'Reviewer';
    case 'friend_count':
      return 'Social Sipper';
    case 'max_drinks_single_shop':
      return 'Shop regular';
    case 'media_upload_count':
      return 'Photographer';
    case 'matcha_drink_count':
      return 'Matcha';
    case 'visited_brands':
      return 'Special';
    case 'all_achievements':
      return 'Completion';
    default:
      return 'Other';
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.row, required this.pinMode});

  final ({Achievement a, int have, int need}) row;
  final bool pinMode;

  @override
  Widget build(BuildContext context) {
    final a = row.a;
    final have = row.have;
    final need = row.need;
    const iconSize = 40.0;
    final locked = have < need && a.isHidden;
    final unlocked = have == need;
    final achievementState = context.watch<AchievementsState>();
    final pinned = achievementState.progressMap[a.id]?.pinned == true;

    return ListTile(
      leading: locked
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: Icon(Icons.question_mark, size: iconSize * 0.75),
            )
          : CircleAvatar(
              radius: iconSize / 2,
              backgroundImage: AssetImage(
                (a.iconPath != null && a.iconPath!.isNotEmpty)
                    ? a.iconPath!
                    : 'lib/assets/badges/first_sip.png',
              ),
              backgroundColor: unlocked
                  ? context.boba.star
                  : context.boba.surfaceAlt,
            ),
      title: Text(locked ? 'Hidden' : a.name),
      subtitle: Text(locked ? '? ? ?' : a.description),
      trailing: pinMode && unlocked
          ? IconButton(
              tooltip: pinned ? 'Unpin' : 'Pin',
              onPressed: () => achievementState.setPinned(a.id),
              icon: Icon(
                pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: pinned ? context.boba.accent : context.boba.inkMuted,
              ),
            )
          : unlocked
          ? Icon(Icons.check_circle_rounded, color: context.boba.success)
          : Text(
              '$have/$need',
              style: TextStyle(fontSize: 16, color: context.boba.inkMuted),
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
                color: context.boba.outline,
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
                      color: context.boba.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity, // longer bottom line
                    decoration: BoxDecoration(
                      color: context.boba.outline,
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

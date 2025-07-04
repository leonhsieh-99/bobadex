import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsPage extends StatelessWidget {
  final String userId;

  const AchievementsPage({super.key, required this.userId});

  String normalizer(String name) {
    return name
      .toLowerCase()
      .replaceAll('_', '')
      .replaceAll(RegExp(r'\s+'), '');
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = context.watch<AchievementsState>();
    final shopState = context.watch<ShopState>();
    final drinkState = context.watch<DrinkState>();
    final friendState = context.watch<FriendState>();
    final shopMediaState = context.watch<ShopMediaState>();
    final achievements = achievementState.achievements;
    return Scaffold(
      appBar: AppBar(title: Text('Achievements')),
      body: ListView.builder(
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index];
          final dependsOn = a.dependsOn;
          int count = 0;
          int min = 0;

          switch (dependsOn['type']) {
            case 'shop_count':
              count = shopState.all.length;
              min = dependsOn['min'];
              break;
            case 'drink_count':
              count = drinkState.all.length;
              min = dependsOn['min'];
              break;
            case 'drink_notes_count':
              count = drinkState.all.where((d) => d.notes != null && d.notes!.isNotEmpty).toList().length;
              min = dependsOn['min'];
              break;
            case 'friend_count':
              count = friendState.friends.length;
              min = dependsOn['min'];
              break;
            case 'max_drinks_single_shop':
              final Map<String, int> shopDrinkCounts = {};
              for (var drink in drinkState.all) {
                final shopId = drink.shopId;
                if (shopId != null) {
                  shopDrinkCounts[shopId] = (shopDrinkCounts[shopId] ?? 0) + 1;
                }
              }
              count = shopDrinkCounts.values.isEmpty ? 0 : shopDrinkCounts.values.reduce((a, b) => a > b ? a : b);
              min = dependsOn['min'];
              break;
            case 'media_upload_count':
              count = shopMediaState.all.length;
              min = dependsOn['min'];
              break;
            case 'matcha_drink_count':
              count = drinkState.all.where((d) => d.name.toLowerCase().split(' ').contains('matcha')).length;
              min = dependsOn['min'];
            case 'visited_brands':
              final brands = dependsOn['brands'];
              final normalBrands = shopState.all.map((s) => normalizer(s.name));
              for (var brand in brands) {
                if (normalBrands.contains(brand)) {
                  count += 1;
                }
              }
              min = brands.length;
              break;
            case 'all_achievements':
              count = achievementState.progressMap.values.where((a) => a.unlocked).length;
              min = achievements.length - 1;
              break;
          }
          if (count >= min) {
            count = min;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('lib/assets/default_badge.png'),
              backgroundColor: count == min ? Colors.amber : Colors.grey[300],
            ),
            title: Text(a.isHidden && (count != min) ? 'Hidden' : a.name),
            subtitle: Text(a.isHidden && (count != min) ? '? ? ?' : a.description),
            trailing: count == min
                ? Icon(Icons.check_circle, color: Colors.green)
                : Text('$count/$min', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          );
        },
      ),
    );
  }
}

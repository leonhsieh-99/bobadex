import 'package:bobadex/state/achievements_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AchievementsPage extends StatelessWidget {
  final String userId;

  const AchievementsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final achievementState = context.watch<AchievementsState>();
    final achievements = achievementState.achievements;
    final progressMap = achievementState.progressMap;
    return Scaffold(
      appBar: AppBar(title: Text('Achievements')),
      body: ListView.builder(
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final a = achievements[index];
          final ua = progressMap[a.id];

          final isUnlocked = ua?.unlocked ?? false;
          final progress = ua?.progress ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('lib/assets/default_badge.png'),
              backgroundColor: isUnlocked ? Colors.amber : Colors.grey[300],
            ),
            title: Text(a.name),
            subtitle: Text(a.description),
            trailing: isUnlocked
                ? Icon(Icons.check_circle, color: Colors.green)
                : Text('$progress', style: TextStyle(color: Colors.grey[600])),
          );
        },
      ),
    );
  }
}

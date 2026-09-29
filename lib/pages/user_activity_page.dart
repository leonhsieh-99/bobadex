import 'package:bobadex/widgets/social_widgets/user_feed_view.dart';
import 'package:flutter/material.dart';

class UserActivityPage extends StatelessWidget {
  const UserActivityPage({
    super.key,
    required this.userId,
    required this.isOwner,
  });

  final String userId;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent activity')),
      body: UserFeedView(userId: userId, isOwner: isOwner, pageSize: 20),
    );
  }
}

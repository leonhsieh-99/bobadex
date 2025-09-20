import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage ({
    super.key,
  });

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  @override
  Widget build(BuildContext context) {
    final friendState = context.watch<FriendState>();
    final achievementState = context.watch<AchievementsState>();
    final analytics = context.read<AnalyticsService>();
    final user = context.watch<UserState>().current;
    final themeColor = Constants.getThemeColor(user.themeSlug);
    final incomingRequests = friendState.incomingRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: incomingRequests.isEmpty
        ? Center(
          child: Text(
            'No  friend requests',
            style: Constants.emptyListTextStyle,
          ),
        )
        : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: incomingRequests.length,
                itemBuilder: (context, index) {
                  final requester = incomingRequests[index];
                  return ListTile(
                    title: Text(requester.username),
                    subtitle: Text(requester.displayName),
                    leading: ThumbPic(path: requester.profileImagePath, size: 60),
                    minLeadingWidth: 60,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AccountViewPage(userId: requester.id, user: requester))
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: 40,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: themeColor.shade500),
                          ),
                          child: IconButton(
                            onPressed: () {
                              try {
                                friendState.acceptUser(requester.id);
                                analytics.friendRequestAccepted();
                                achievementState.checkAndUnlockFriendAchievement(friendState);
                                notify('Friend added', SnackType.info);
                              } catch (e) {
                                notify('Error adding friend', SnackType.error);
                              }
                            },
                            icon: Icon(
                              Icons.check,
                              size: 20,
                            )
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: 40,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: themeColor.shade500),
                          ),
                          child: IconButton(
                            onPressed: () {
                              try {
                                friendState.rejectUser(requester.id);
                              } catch (e) {
                                notify('Error rejecting user', SnackType.error);
                              }
                            },
                            icon: Icon(
                              Icons.close,
                              size: 20,
                            )
                          ),
                        )
                      ],
                    ),
                  );
                },
              )
            ),
          ],
        ),
    );
  }
}
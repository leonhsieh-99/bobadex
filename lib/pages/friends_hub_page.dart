import 'package:bobadex/pages/friend_requests_page.dart';
import 'package:bobadex/pages/friends_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/social_widgets/feed_view.dart';
import 'package:bobadex/widgets/social_widgets/friends_shop_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsHubPage extends StatelessWidget {
  const FriendsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final requestCount = context.select<FriendState, int>(
      (s) => s.incomingRequests.length,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            IconButton(
              tooltip: 'Friend requests',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendRequestsPage()),
                );
              },
              icon: Badge(
                isLabelVisible: requestCount > 0,
                backgroundColor: context.boba.danger,
                label: Text('$requestCount', style: context.bobaText.badge),
                child: const Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed'),
              Tab(text: 'In common'),
              Tab(text: 'People'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FeedView(),
            FriendsShopGrid(),
            FriendsPage(embedded: true),
          ],
        ),
      ),
    );
  }
}

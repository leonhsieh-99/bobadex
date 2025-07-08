import 'package:bobadex/widgets/social_widgets/feed_view.dart';
import 'package:bobadex/widgets/social_widgets/friends_shop_grid.dart';
import 'package:flutter/material.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        // No appBar here!
        body: SafeArea(
          child: Column(
            children: [
              // TabBar at the top
              const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.rss_feed), text: 'Feed'),
                  Tab(icon: Icon(Icons.people_alt), text: 'Shops'),
                ],
              ),
              // Expanded so TabBarView fills the rest
              Expanded(
                child: TabBarView(
                  children: [
                    FeedView(),
                    FriendsShopGrid(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});
  @override
  Widget build(BuildContext context) {
    final feedState = context.watch<FeedState>();

    if (feedState.isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, i) => FeedEventCardSkeleton(),
      );
    }

    if (feedState.feed.isEmpty) {
      return Center(child: Text("No activity yet!"));
    }

    return RefreshIndicator(
      onRefresh: feedState.fetchFeed,
      child: ListView.builder(
        itemCount: feedState.feed.length,
        itemBuilder: (context, index) {
          final event = feedState.feed[index];
          return FeedEventCard(event: event);
        },
      ),
    );
  }
}

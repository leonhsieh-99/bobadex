import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedState>().fetchFeed(refresh: true);
    });
  }

  void _onScroll() {
    final feedState = context.read<FeedState>();
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      feedState.fetchFeed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = context.watch<FeedState>();

    if (feedState.isLoading && feedState.feed.isEmpty) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, i) => FeedEventCardSkeleton(),
      );
    }

    if (feedState.feed.isEmpty) {
      return Center(child: Text("No activity yet!"));
    }

    return RefreshIndicator(
      onRefresh: () async => feedState.fetchFeed(refresh: true),
      child: ListView.builder(
        controller: _controller,
        itemCount: feedState.feed.length + (feedState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedState.feed.length) {
            return Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ));
          }
          final event = feedState.feed[index];
          return FeedEventCard(event: event);
        },
      ),
    );
  }
}


import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/feed_event_row.dart';
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
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
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
    final bottom = BobaNavBar.clearance(context);

    if (feedState.isLoading && feedState.feed.isEmpty) {
      return ListView.builder(
        padding: EdgeInsets.only(bottom: bottom),
        itemCount: 5,
        itemBuilder: (context, i) => const FeedEventRowSkeleton(),
      );
    }

    if (feedState.feed.isEmpty && feedState.failed) {
      return EmptyState(
        title: 'Could not load the feed',
        body: 'Check your connection and try again.',
        action: BobaButton(
          label: 'Retry',
          onPressed: () => feedState.fetchFeed(refresh: true),
        ),
      );
    }

    if (feedState.feed.isEmpty) {
      return EmptyState(
        title: 'Quiet in here',
        body: "Add friends to see what they're collecting.",
        action: BobaButton(
          label: 'Find friends',
          onPressed: () {
            DefaultTabController.maybeOf(context)?.animateTo(2);
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => feedState.fetchFeed(refresh: true),
      child: CustomScrollView(
        controller: _controller,
        slivers: [
          FeedDaySliverList(
            events: feedState.feed,
            trailing: feedState.hasMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : null,
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottom)),
        ],
      ),
    );
  }
}

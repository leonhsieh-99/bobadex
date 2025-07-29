import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandFeedPage extends StatefulWidget {
  final String brandSlug;
  const BrandFeedPage({super.key, required this.brandSlug});

  @override
  State<BrandFeedPage> createState() => _BrandFeedPageState();
}

class _BrandFeedPageState extends State<BrandFeedPage> {
  final List<FeedEvent> _feed = [];
  bool _hasMore = true;
  bool _isFetching = false;
  final int _limit = 30;
  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController()..addListener(_onScroll);
    fetchFeed(refresh: true);
  }

  void _onScroll() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
      fetchFeed();
    }
  }

  Future<void> fetchFeed({bool refresh = false}) async {
    if (_isFetching) return;
    if (refresh) {
      _feed.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;
    _isFetching = true;
    setState(() {});
    final response = await Supabase.instance.client.rpc('get_brand_feed', params: {
      'brand_slug': widget.brandSlug,
      'offset_count': _feed.length,
      'limit_count': _limit,
    });
    final newFeed = (response as List).map((json) => FeedEvent.fromJson(json)).toList();
    _feed.addAll(newFeed);
    if (newFeed.length < _limit) _hasMore = false;
    _isFetching = false;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_feed.isEmpty && _isFetching) {
      return Scaffold(
        appBar: AppBar(title: Text("Brand Feed")),
        body: ListView.builder(
          itemCount: 5,
          itemBuilder: (context, i) => FeedEventCardSkeleton(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text("Brand Feed")),
      body: RefreshIndicator(
        onRefresh: () async => fetchFeed(refresh: true),
        child: ListView.builder(
          controller: _controller,
          itemCount: _feed.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _feed.length) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final event = _feed[index];
            return FeedEventCard(event: event);
          },
        ),
      ),
    );
  }
}

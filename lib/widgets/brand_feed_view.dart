import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/pages/brand_feed_page.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandFeedView extends StatefulWidget {
  final String brandSlug;
  const BrandFeedView({super.key, required this.brandSlug});
  @override
  State<BrandFeedView> createState() => _BrandFeedViewState();
}

class _BrandFeedViewState extends State<BrandFeedView> {
  bool isLoading = true;
  List<FeedEvent> feed = [];
  bool hasMore = false;

  @override
  void initState() {
    super.initState();
    fetchFeed(limit: 11);
  }

  Future<void> fetchFeed({int limit = 50}) async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client.rpc('get_brand_feed', params: {
        'brand_slug': widget.brandSlug,
        'limit_count': limit,
      });
      final items = (response as List).map((json) => FeedEvent.fromJson(json)).toList();
      setState(() {
        hasMore = items.length == limit;
        feed = items.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading feed: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(3, (_) => FeedEventCardSkeleton()),
      );
    }
    if (feed.isEmpty) {
      return Center(child: Text("No activity yet!", style: Constants.emptyListTextStyle));
    }
    return Column(
      children: [
        ...feed.map((event) => FeedEventCard(event: event)),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BrandFeedPage(brandSlug: widget.brandSlug),
                  ),
                );
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: Text('See more', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ),
          ),
      ],
    );
  }
}

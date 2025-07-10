import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/widgets.dart';
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

  @override
  void initState() {
    super.initState();
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    setState(() => isLoading = true);
    try {
      final response = await Supabase.instance.client.rpc('get_brand_feed', params: {
        'brand_slug': widget.brandSlug,
        'limit_count': 50,
      });
      feed = (response as List).map((json) => FeedEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading feed: $e');
    }
    setState(() => isLoading = false);
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
      children: List.generate(feed.length, (index) {
        final event = feed[index];
        return FeedEventCard(event: event);
      }),
    );
  }
}

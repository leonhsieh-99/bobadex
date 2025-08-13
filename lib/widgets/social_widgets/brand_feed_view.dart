import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/widgets/social_widgets/feed_card_options.dart';
import 'package:bobadex/widgets/social_widgets/feed_event_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandFeedView extends StatefulWidget {
  final String brandSlug;
  final int pageSize;
  const BrandFeedView({super.key, required this.brandSlug, this.pageSize = 10});

  @override
  State<BrandFeedView> createState() => _BrandFeedViewState();
}

class _BrandFeedViewState extends State<BrandFeedView> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;

  DateTime? _cursorTs;
  int? _cursorSeq;
  final List<FeedEvent> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch(initial: true);
  }

  Future<void> _fetch({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _isLoadingMore = false;
        _hasMore = true;
        _cursorTs = null;
        _cursorSeq = null;
        _items.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final params = {
        '_brand_slug': widget.brandSlug,
        '_limit': widget.pageSize,
        '_before_ts': _cursorTs?.toIso8601String(),
        '_before_seq': _cursorSeq,
      };

      final resp = await _supabase.rpc('get_brand_feed', params: params);
      final list = (resp is List) ? resp : const <dynamic>[];

      final items = list
          .map((j) => FeedEvent.fromJson(j as Map<String, dynamic>))
          .toList();

      if (items.isNotEmpty) {
        final last = items.last;
        _cursorTs = last.createdAt;
        _cursorSeq = last.seq;
      }

      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _hasMore = items.length == widget.pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('BrandFeedView fetch error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        children: List.generate(3, (_) => const FeedEventCardSkeleton()),
      );
    }

    if (_items.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Center(
          child: Text("No activity yet", style: Constants.emptyListTextStyle, textAlign: TextAlign.center),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, i) => FeedEventCard(
            event: _items[i],
            variant: FeedCardVariant.brand,
          ),
        ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: () => _fetch(initial: false),
                    child: const Text('Load more'),
                  ),
          ),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: () => _fetch(initial: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
      ],
    );
  }
}

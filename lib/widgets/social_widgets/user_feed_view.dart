import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/ui/components/feed_event_row.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/social_widgets/feed_card_options.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserFeedView extends StatefulWidget {
  final String userId;
  final bool isOwner;
  final int pageSize;

  const UserFeedView({
    super.key,
    required this.userId,
    required this.isOwner,
    this.pageSize = 10,
  });

  @override
  State<UserFeedView> createState() => _UserFeedViewState();
}

class _UserFeedViewState extends State<UserFeedView> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

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
        '_user_id': widget.userId,
        '_limit': widget.pageSize,
        '_before_ts': _cursorTs?.toIso8601String(),
        '_before_seq': _cursorSeq,
      };

      final resp = await _supabase.rpc('get_user_feed', params: params);
      final items = (resp as List)
          .map((j) => FeedEvent.fromJson(j as Map<String, dynamic>))
          .toList();

      if (items.isNotEmpty) {
        final last = items.last;
        _cursorTs = last.createdAt;
        _cursorSeq = last.seq;
      }

      setState(() {
        _items.addAll(items);
        _hasMore = items.length == widget.pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('UserFeedView fetch error: $e');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return ListView(
        children: List.generate(5, (_) => const FeedEventRowSkeleton()),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Text(
            widget.isOwner
                ? "You haven't posted anything yet"
                : 'No activity yet',
            style: context.bobaText.empty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        FeedDaySliverList(
          events: _items,
          variant: FeedCardVariant.userProfile,
          trailing: Column(
            children: [
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
              TextButton.icon(
                onPressed: () => _fetch(initial: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

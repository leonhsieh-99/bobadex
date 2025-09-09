import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/retry_helper.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bobadex/models/user.dart' as u;

class FeedState extends ChangeNotifier {
  final List<FeedEvent> _feed = [];
  final Set<String> _seenIds = {};
  bool _hasMore = true;
  bool _isFetchingMore = false;
  final int _limit = Constants.defaultFeedLimit;

  List<FeedEvent> get feed => _feed;
  bool get hasMore => _hasMore;
  bool get isLoading => _isFetchingMore;

  DateTime? cursorTs;
  int? cursorSeq;

  Future<void> fetchFeed({bool refresh = false}) async {
    final supabase = Supabase.instance.client;
    if (_isFetchingMore) return;

    if (refresh) {
      _feed.clear();
      _seenIds.clear();
      _hasMore = true;
      cursorTs = null;
      cursorSeq = null;
    }
    if (!_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final response = await RetryHelper.retry(() => supabase
        .rpc('get_feed', params: {
          '_user_id': supabase.auth.currentUser!.id,
          '_limit': _limit,
          '_before_ts': cursorTs?.toIso8601String(),
          '_before_seq': cursorSeq,
        }));

      final list = (response is List) ? response : <dynamic>[];
      final newFeed = list
        .map((j) => FeedEvent.fromJson(j as Map<String, dynamic>))
        .toList();

      if (newFeed.isNotEmpty) {
        final last = newFeed.last;
        cursorTs = last.createdAt;
        cursorSeq = last.seq;
      }

      _feed.addAll(newFeed);
      _hasMore = newFeed.length == _limit;
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<FeedEvent> finalizeShopAdd({
    required u.User currentUser,
    required String shopId,
  }) async {
    try {
      final row = await Supabase.instance.client
        .rpc('finalize_shop_add_event', params: {
          '_shop_id': shopId,
          '_user_id': currentUser.id,
        })
        .single();

      final event = FeedEvent.fromJson(row);

      if (_seenIds.add(event.id)) {
        _feed.insert(0, event);
        if (cursorTs == null || event.createdAt.isAfter(cursorTs!)) {
          cursorTs = event.createdAt;
          cursorSeq = event.seq;
        }
        notifyListeners();
      }

      return event;
    } catch (e) {
      debugPrint('Insert feed event failed: $e');
      rethrow;
    }
  }

  Future<void> removeFeedEvent(String objectId) async {
    final idx = _feed.indexWhere((f) => f.objectId == objectId);
    if (idx == -1) return;
    final item = _feed.removeAt(idx);
    _seenIds.remove(item.id);
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('feed_events')
          .delete()
          .eq('object_id', objectId);
    } catch (e) {
      debugPrint('Error removing feed event: $e');
      _feed.insert(idx, item);
      _seenIds.add(item.id);
      notifyListeners();
      rethrow;
    }
  }

  void removeImageCache(String id) {
    _feed.removeWhere((fe) => fe.eventType == 'shop_add' && fe.payload['images'].contains(id));
    notifyListeners();
  }

  void reset() {
    _feed.clear();
    _seenIds.clear();
    _hasMore = true;
    _isFetchingMore = false;
    cursorTs = null;
    cursorSeq = null;
    notifyListeners();
  }
}
import 'package:bobadex/models/feed_event.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FeedState extends ChangeNotifier {
  final List<FeedEvent> _feed = [];
  bool _hasMore = false;
  bool _isFetchingMore = false;
  final int _limit = 50;

  List<FeedEvent> get feed => _feed;
  bool get hasMore => _hasMore;
  bool get isLoading => _isFetchingMore;

  Future<void> fetchFeed({bool refresh = false}) async {
    final supabase = Supabase.instance.client;
    if (_isFetchingMore) return;

    if (refresh) {
      _feed.clear();
      _hasMore = true;
    }

    if (!_hasMore) return;

    _isFetchingMore = true;
    notifyListeners();

    final response = await supabase
      .rpc('get_feed', params: {
        'user_id': supabase.auth.currentUser!.id,
        'offset_count': _feed.length,
        'limit_count': _limit,
      });
    final newFeed = (response as List).map((json) => FeedEvent.fromJson(json)).toList();
    _feed.addAll(newFeed);

    if (newFeed.length < _limit) _hasMore = false;

    _isFetchingMore = false;
    notifyListeners();
  }

  Future<FeedEvent> addFeedEvent(FeedEvent event) async {
    final tempId = Uuid().v4();
    _feed.insert(0, event.copyWith(id: tempId));
    notifyListeners();
    try {
      final response = await Supabase.instance.client
        .from('feed_events')
        .insert({
          'user_id': event.feedUser.id,
          'object_id': event.objectId,
          'event_type': event.eventType,
          'payload': event.payload,
          'brand_slug': event.brandSlug,
          'is_backfill': event.isBackfill,
        })
        .select()
        .single();

      final insertedEvent = FeedEvent.fromJson(response);
      insertedEvent.feedUser = event.feedUser;
      final index = _feed.indexWhere((e) => e.id == tempId);
      if (index != -1) {
        _feed[index] = insertedEvent;
        notifyListeners();
        return insertedEvent;
      }
      throw StateError('Error with temp id');
    } catch (e) {
      debugPrint('Insert feed event failed: $e');
      _feed.removeWhere((e) => e.id == tempId);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFeedEvent(String objectId) async {
    final index = _feed.indexWhere((f) => f.objectId == objectId);
    if (index != -1) {
      final feedEvenet = _feed[index];
      _feed.removeAt(index);
      notifyListeners();

      try {
        await Supabase.instance.client
          .from('feed_events')
          .delete()
          .eq('object_id', objectId);
      } catch (e) {
        debugPrint('Error removing feed event: $e');
        _feed.insert(index, feedEvenet);
        notifyListeners();
        rethrow;
      }
    }
  }

  void reset() {
    _feed.clear();
  }
}
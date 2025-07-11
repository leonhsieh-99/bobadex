import 'package:bobadex/models/feed_event.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class FeedState extends ChangeNotifier {
  final List<FeedEvent> _feed = [];
  bool _isLoading = false;

  List<FeedEvent> get feed => _feed;
  bool get isLoading => _isLoading;

  Future<void> fetchFeed() async {
    final supabase = Supabase.instance.client;
    _isLoading = true;
    final response = await supabase
      .rpc('get_feed', params: {
        'user_id': supabase.auth.currentUser!.id,
        'limit_count': 50,
      });
    _feed
      ..clear()
      ..addAll((response as List).map((json) => FeedEvent.fromJson(json)));
    _isLoading = false;
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
      final index = _feed.indexWhere((e) => e.id == tempId);
      if (index != -1) {
        _feed[index] = insertedEvent;
        notifyListeners();
        return insertedEvent;
      }
      throw StateError('Error with temp id');
    } catch (e) {
      debugPrint('Insert failed: $e');
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
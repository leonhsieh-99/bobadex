import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_suggestion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionRepository {
  CollectionRepository([SupabaseClient? client]) : _clientOverride = client;

  final SupabaseClient? _clientOverride;

  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static const pageSize = 50;

  Future<List<CountySummary>> availableCounties() async {
    final rows = await _client.rpc('get_available_county_collections');
    return _summaries(rows);
  }

  Future<List<CountySummary>> trackedCounties() async {
    final rows = await _client.rpc('get_user_tracked_county_collections');
    return _summaries(rows);
  }

  Future<CountyDetail?> countyDetail({
    required String countyPlaceId,
    int limit = pageSize,
    int offset = 0,
    String filter = 'all',
    String sort = 'name',
  }) async {
    final row = await _client.rpc(
      'get_county_collection_detail',
      params: {
        'p_county_place_id': countyPlaceId,
        'p_limit': limit,
        'p_offset': offset,
        'p_filter': filter,
        'p_sort': sort,
      },
    );
    if (row == null) return null;
    if (row is Map) {
      return CountyDetail.fromJson(Map<String, dynamic>.from(row));
    }
    return null;
  }

  Future<void> track(String countyPlaceId) async {
    await _client.rpc(
      'track_county_collection',
      params: {'p_county_place_id': countyPlaceId},
    );
  }

  Future<String?> countyPlaceIdAt({
    required double lat,
    required double lon,
  }) async {
    final id = await _client.rpc(
      'county_collection_at_point',
      params: {'p_lat': lat, 'p_lon': lon},
    );
    if (id is String && id.isNotEmpty) return id;
    return null;
  }

  Future<List<CollectionSuggestion>> mySuggestions(
    String countyPlaceId, {
    int limit = 50,
  }) async {
    final rows = await _client.rpc(
      'get_my_collection_suggestions',
      params: {'p_county_place_id': countyPlaceId, 'p_limit': limit},
    );
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map(
          (row) =>
              CollectionSuggestion.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<CollectionSuggestionResult> submitSuggestion({
    required String countyPlaceId,
    required String brandSlug,
    required String action,
    String? note,
  }) async {
    if (_client.auth.currentSession == null) {
      return const CollectionSuggestionResult(
        status: 'authentication_required',
      );
    }
    try {
      final row = await _client.rpc(
        'submit_collection_suggestion',
        params: {
          'p_county_place_id': countyPlaceId,
          'p_brand_slug': brandSlug,
          'p_action': action,
          'p_note': note,
        },
      );
      return CollectionSuggestionResult.parse(row);
    } on PostgrestException catch (e) {
      return CollectionSuggestionResult(
        status: collectionSuggestionErrorCode(e.message, e.code),
      );
    }
  }

  Future<void> untrack(String countyPlaceId) async {
    await _client.rpc(
      'untrack_county_collection',
      params: {'p_county_place_id': countyPlaceId},
    );
  }

  List<CountySummary> _summaries(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => CountySummary.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

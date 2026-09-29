import 'package:bobadex/collection/collection_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectionRepository {
  CollectionRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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

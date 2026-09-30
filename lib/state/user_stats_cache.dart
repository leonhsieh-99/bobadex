import 'package:bobadex/helpers/ttl_cache.dart';
import 'package:bobadex/models/account_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatsCache {
  final _cache = TtlCache<AccountStats>();

  Future<Map<String, dynamic>> fetchStatsFromServer(String userId) async {
    final response = await Supabase.instance.client.rpc(
      'get_user_stats',
      params: {'uid': userId},
    );
    if (response is List && response.isNotEmpty) {
      return response.first;
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchTopShopFromServer(String userId) async {
    final response = await Supabase.instance.client.rpc(
      'get_user_top_shop_info',
      params: {'user_id': userId},
    );
    if (response is List && response.isNotEmpty) {
      return response.first;
    }
    return {};
  }

  Future<AccountStats> getStats(String userId) {
    return _cache.get(userId, () async {
      final results = await Future.wait([
        fetchStatsFromServer(userId),
        fetchTopShopFromServer(userId),
      ]);
      return AccountStats.fromJson(results[0], results[1]);
    });
  }

  void clearCache() => _cache.invalidate();
}

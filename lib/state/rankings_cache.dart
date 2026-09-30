import 'package:bobadex/helpers/ttl_cache.dart';
import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/user_stats.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Short-lived rankings so the profile preview and the full board share one fetch.
class RankingsCache {
  static final users = TtlCache<List<UserStats>>();
  static final brands = TtlCache<List<BrandStats>>();

  static Future<List<UserStats>> userRankings(String metric) {
    return users.get(metric, () async {
      final rows = await Supabase.instance.client.rpc(
        'get_user_rankings',
        params: {'p_metric': metric},
      );
      return (rows as List)
          .map((json) => UserStats.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }

  static Future<List<BrandStats>> brandRankings(String metric) {
    return brands.get(metric, () async {
      final rows = await Supabase.instance.client.rpc(
        'get_brand_rankings',
        params: {'p_metric': metric},
      );
      return (rows as List)
          .map((json) => BrandStats.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    });
  }
}

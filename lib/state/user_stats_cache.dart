import 'package:bobadex/models/account_stats.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class UserStatsCache extends ChangeNotifier {
  final _cache = <String, AccountStats> {};

  Future<Map<String, dynamic>> fetchStatsFromServer(userId) async {
    final response = await Supabase.instance.client
      .rpc('get_user_stats', params: {'uid': userId});
    if (response is List && response.isNotEmpty) {
      return response.first;
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchTopShopFromServer(userId) async {
    final response = await Supabase.instance.client
      .rpc('get_user_top_shop_info', params: {'user_id': userId});
    if (response is List && response.isNotEmpty) {
      return response.first;
    }
    return {};
  }

  Future<AccountStats> getStats(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }
    final stats = await fetchStatsFromServer(userId);
    final topShop = await fetchTopShopFromServer(userId);
    final accountStats = AccountStats.fromJson(stats, topShop);
    _cache[userId] = accountStats;
    return accountStats;
  }

  void clearCache() => _cache.clear();
}
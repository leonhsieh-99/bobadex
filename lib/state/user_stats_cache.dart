import 'package:bobadex/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserStatsCache extends ChangeNotifier {
  final _cache = <String, Map<String, dynamic>> {};

  Future<Map<String, dynamic>> fetchStatsFromServer(userId) async {
    final response = await Supabase.instance.client
      .rpc('get_user_stats', params: {'uid': userId})
      .single();
    return response ?? Constants.emptyStats;
  }

  Future<Map<String, dynamic>> getStats(String userId) async {
    if (_cache.containsKey(userId)) {
      return _cache[userId]!;
    }
    final stats = await fetchStatsFromServer(userId);
    _cache[userId] = stats;
    notifyListeners();
    return stats;
  }

  void clearCache() => _cache.clear();
}
import 'package:bobadex/helpers/app_prefs.dart';
import 'package:bobadex/navigation.dart';
import 'package:bobadex/push/push_registration.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/feed_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/rankings_cache.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/state/user_stats_cache.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Drops this device's session and the signed-in user's local data.
///
/// A deleted Auth user can make the server sign-out call fail. The local
/// session is still removed, and this does not touch another device's token.
Future<void> clearLocalAccount(BuildContext context) async {
  await PushRegistration.removeCurrent();
  try {
    await Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
  } catch (_) {}
  try {
    await FirebaseMessaging.instance.deleteToken();
  } catch (_) {}

  if (context.mounted) {
    context.read<UserState>().reset();
    context.read<DrinkState>().reset();
    context.read<ShopState>().reset();
    context.read<BrandState>().reset();
    context.read<FriendState>().reset();
    context.read<UserStatsCache>().clearCache();
    context.read<ShopMediaState>().reset();
    context.read<AchievementsState>().reset();
    context.read<FeedState>().reset();
  }
  RankingsCache.users.invalidate();
  RankingsCache.brands.invalidate();

  try {
    await DefaultCacheManager().emptyCache();
  } catch (_) {}
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();

  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(AppPrefs.dismissedCountySuggestionKey);
  await prefs.remove(AppPrefs.locationPromptedKey);
  await goRoot('/auth');
}

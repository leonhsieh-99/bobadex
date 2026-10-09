import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/shop_state.dart';

Future<Shop> saveShopVisit({
  required Shop shop,
  required bool isNew,
  required ShopState shopState,
  required AchievementsState achievements,
  required AnalyticsService analytics,
}) async {
  if (!isNew) return shopState.update(shop);
  final persisted = await shopState.add(shop);
  analytics.shopAdded(rating: persisted.rating, brandSlug: persisted.brandSlug);
  await achievements.checkAndUnlockShopAchievement(shopState);
  await achievements.checkAndUnlockBrandAchievement(shopState);
  return persisted;
}

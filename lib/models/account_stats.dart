class AccountStats {
  final int shopCount;
  final int drinkCount;
  final String topShopId;
  final String topDrinkName;
  final String topShopIcon;
  final String topShopSlug;

  const AccountStats({
    required this.shopCount,
    required this.drinkCount,
    required this.topShopId,
    required this.topDrinkName,
    required this.topShopIcon,
    required this.topShopSlug,
  });

  factory AccountStats.fromJson(Map<String, dynamic> stats, Map<String, dynamic> topShop) {
    return AccountStats(
      shopCount: stats['num_shops'] ?? 0,
      drinkCount: stats['num_drinks'] ?? 0,
      topShopId: topShop['shop_id'] ?? '',
      topDrinkName: topShop['drink_name'] ?? '',
      topShopIcon: topShop['icon_path'] ?? '',
      topShopSlug: topShop['brand_slug'] ?? '',
    );
  }

  static AccountStats emptyStats() {
    return AccountStats(shopCount: 0, drinkCount: 0, topShopId: '', topDrinkName: '', topShopIcon: '', topShopSlug: '');
  }
}
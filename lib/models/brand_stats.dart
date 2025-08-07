import 'package:bobadex/models/brand.dart';

class BrandStats extends Brand {
  final double avgRating;
  final int shopCount;

  BrandStats({
    required super.slug,
    required super.display,
    required super.iconPath,
    required this.avgRating,
    required this.shopCount,
  });

  factory BrandStats.fromJson(Map<String, dynamic> json) {
    return BrandStats(
      slug: json['brand_slug'],
      display: json['brand_display'],
      iconPath: json['brand_icon'],
      avgRating: (json['avg_rating'] as num).toDouble(),
      shopCount: (json['shop_count'] ?? 0) as int,
    );
  }
}
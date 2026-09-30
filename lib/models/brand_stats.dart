import 'package:bobadex/models/brand.dart';

class BrandStats extends Brand {
  final double avgRating;
  final int shopCount;
  final double metricValue;
  final int rank;

  BrandStats({
    required super.slug,
    required super.display,
    required super.iconPath,
    required this.avgRating,
    required this.shopCount,
    this.metricValue = 0,
    this.rank = 0,
  });

  factory BrandStats.fromJson(Map<String, dynamic> json) {
    final shopCount = _asInt(json['shop_count']);
    return BrandStats(
      slug: json['brand_slug'] ?? '',
      display: json['brand_display'] ?? '',
      iconPath: json['brand_icon'],
      avgRating: _asDouble(json['avg_rating']) ?? 0,
      shopCount: shopCount,
      metricValue: _asDouble(json['metric_value']) ?? shopCount.toDouble(),
      rank: _asInt(json['rank']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

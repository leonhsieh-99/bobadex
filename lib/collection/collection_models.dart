class CountySummary {
  const CountySummary({
    required this.countyPlaceId,
    required this.countyName,
    required this.stateName,
    required this.eligibleTotal,
    required this.discoveredTotal,
    required this.isTracked,
  });

  final String countyPlaceId;
  final String countyName;
  final String stateName;
  final int eligibleTotal;
  final int discoveredTotal;
  final bool isTracked;

  bool get isComplete => eligibleTotal > 0 && discoveredTotal >= eligibleTotal;

  factory CountySummary.fromJson(Map<String, dynamic> json) {
    return CountySummary(
      countyPlaceId: json['county_place_id'] as String,
      countyName: (json['county_name'] as String?) ?? 'County',
      stateName: (json['state_name'] as String?) ?? '',
      eligibleTotal: _asInt(json['eligible_total']),
      discoveredTotal: _asInt(json['discovered_total']),
      isTracked: json['is_tracked'] == true,
    );
  }
}

class CountyBrand {
  const CountyBrand({
    required this.brandSlug,
    required this.display,
    required this.localStorefronts,
    required this.discovered,
    this.iconPath,
    this.eligibilityRoute,
  });

  final String brandSlug;
  final String display;
  final String? iconPath;
  final int localStorefronts;
  final bool discovered;
  final String? eligibilityRoute;

  factory CountyBrand.fromJson(Map<String, dynamic> json) {
    return CountyBrand(
      brandSlug: (json['brand_slug'] as String?) ?? '',
      display: (json['display'] as String?) ?? 'Brand',
      iconPath: json['icon_path'] as String?,
      localStorefronts: _asInt(json['local_storefronts']),
      discovered: json['discovered'] == true,
      eligibilityRoute: json['eligibility_route'] as String?,
    );
  }
}

class CountyDetail {
  const CountyDetail({
    required this.countyPlaceId,
    required this.eligibleTotal,
    required this.discoveredTotal,
    required this.undiscoveredTotal,
    required this.items,
  });

  final String countyPlaceId;
  final int eligibleTotal;
  final int discoveredTotal;
  final int undiscoveredTotal;
  final List<CountyBrand> items;

  factory CountyDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map((e) => CountyBrand.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : const <CountyBrand>[];
    return CountyDetail(
      countyPlaceId: json['county_place_id'] as String,
      eligibleTotal: _asInt(json['eligible_total']),
      discoveredTotal: _asInt(json['discovered_total']),
      undiscoveredTotal: _asInt(json['undiscovered_total']),
      items: items,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String countyAbbreviation(String name) {
  final words = name
      .replaceAll(RegExp(r'\bcounty\b', caseSensitive: false), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  final letters = words.map((word) => word[0].toUpperCase()).take(3).join();
  return letters.isEmpty ? '?' : letters;
}

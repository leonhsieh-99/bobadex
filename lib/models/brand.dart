import 'package:supabase_flutter/supabase_flutter.dart';

enum BrandStatus { active, retired, merged }

extension BrandStatusX on BrandStatus {
  String get db => name;
  String get label => switch (this) {
    BrandStatus.retired => 'Closed',
    BrandStatus.merged => 'Merged',
    BrandStatus.active => 'Open',
  };
  bool get isActive => this == BrandStatus.active;
}

BrandStatus _brandStatusFromDb(String? s) => switch (s) {
  'retired' => BrandStatus.retired,
  'merged' => BrandStatus.merged,
  _ => BrandStatus.active,
};

final _nonAlphanumeric = RegExp(r'[^a-z0-9]');

String normalizeBrandQuery(String value) =>
    value.toLowerCase().replaceAll(_nonAlphanumeric, '');

class BrandAlias {
  final String normalizedName;
  final String? aliasDisplay;
  final String matchMode;

  BrandAlias({
    required this.normalizedName,
    this.aliasDisplay,
    this.matchMode = 'exact',
  });

  String get searchLabel =>
      (aliasDisplay != null && aliasDisplay!.trim().isNotEmpty)
      ? aliasDisplay!.trim()
      : normalizedName;

  bool matches(String query, String normalizedQuery) {
    if (searchLabel.toLowerCase().contains(query)) return true;
    if (normalizedQuery.length >= 2 &&
        normalizedName.contains(normalizedQuery)) {
      return true;
    }
    return false;
  }

  factory BrandAlias.fromJson(dynamic json) {
    if (json is String) {
      return BrandAlias(
        normalizedName: normalizeBrandQuery(json),
        aliasDisplay: json,
      );
    }
    final map = Map<String, dynamic>.from(json as Map);
    return BrandAlias(
      normalizedName: (map['normalized_name'] as String?) ?? '',
      aliasDisplay: map['alias_display'] as String?,
      matchMode: (map['match_mode'] as String?) ?? 'exact',
    );
  }

  Map<String, dynamic> toJson() => {
    'normalized_name': normalizedName,
    'alias_display': aliasDisplay,
    'match_mode': matchMode,
  };
}

class BrandPlace {
  final String city;
  final String state;
  final double? latitude;
  final double? longitude;
  final int count;

  const BrandPlace({
    required this.city,
    required this.state,
    this.latitude,
    this.longitude,
    this.count = 1,
  });

  String get key => '${city.toLowerCase()}|${state.toLowerCase()}';

  String get label => state.isEmpty ? city : '$city, $state';

  factory BrandPlace.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'];
    final lon = json['lon'];
    return BrandPlace(
      city: (json['city'] as String?)?.trim() ?? '',
      state: (json['state'] as String?)?.trim() ?? '',
      latitude: lat is num ? lat.toDouble() : null,
      longitude: lon is num ? lon.toDouble() : null,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'state': state,
    'lat': latitude,
    'lon': longitude,
    'count': count,
  };
}

class Brand {
  final String slug;
  final String display;
  final List<BrandAlias> aliases;
  final String? iconPath;
  BrandStatus status;
  final String? website;
  final List<BrandPlace> places;
  final int locationCount;

  Brand({
    required this.slug,
    required this.display,
    List<BrandAlias>? aliases,
    this.iconPath,
    this.status = BrandStatus.active,
    this.website,
    List<BrandPlace>? places,
    int? locationCount,
  }) : aliases = aliases ?? [],
       places = places ?? const [],
       locationCount = locationCount ?? _locationCountOf(places);

  Brand withPlaces(List<BrandPlace> places, int locationCount) {
    return Brand(
      slug: slug,
      display: display,
      aliases: aliases,
      iconPath: iconPath,
      status: status,
      website: website,
      places: places,
      locationCount: locationCount,
    );
  }

  String get imageUrl => iconPath != null && iconPath!.isNotEmpty
      ? Supabase.instance.client.storage
            .from('shop-media')
            .getPublicUrl(iconPath!.trim())
      : '';

  bool matchesQuery(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    if (query.isEmpty) return false;
    if (display.toLowerCase().contains(query)) return true;

    final normalizedQuery = normalizeBrandQuery(query);
    if (normalizedQuery.length >= 2 &&
        normalizeBrandQuery(display).contains(normalizedQuery)) {
      return true;
    }

    return aliases.any((alias) => alias.matches(query, normalizedQuery));
  }

  /// Alias label to show when the query hit an alternate name, not the display name.
  String? matchingAliasLabel(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    if (query.isEmpty) return null;
    if (display.toLowerCase().contains(query)) return null;

    final normalizedQuery = normalizeBrandQuery(query);
    for (final alias in aliases) {
      if (!alias.matches(query, normalizedQuery)) continue;
      final label = alias.searchLabel;
      if (label.toLowerCase() == display.toLowerCase()) continue;
      return label;
    }
    return null;
  }

  int matchRank(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    final displayLower = display.toLowerCase();
    if (displayLower.startsWith(query)) return 0;
    if (aliases.any((a) => a.searchLabel.toLowerCase().startsWith(query))) {
      return 1;
    }
    if (displayLower.contains(query)) return 2;
    return 3;
  }

  factory Brand.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['brand_aliases'] ?? json['aliases'];
    return Brand(
      slug: json['slug'],
      display: json['display'],
      aliases: _parseAliases(rawAliases),
      iconPath: json['icon_path'],
      status: _brandStatusFromDb(json['status'] as String?),
      website: json['website'] as String?,
      places: _parsePlaces(json['places']),
      locationCount: (json['location_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'display': display,
      'aliases': aliases.map((a) => a.toJson()).toList(),
      'icon_path': iconPath,
      'status': status.db,
      'website': website,
      'places': places.map((place) => place.toJson()).toList(),
      'location_count': locationCount,
    };
  }
}

List<BrandAlias> _parseAliases(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map(BrandAlias.fromJson).toList();
}

List<BrandPlace> _parsePlaces(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => BrandPlace.fromJson(Map<String, dynamic>.from(item)))
      .where((place) => place.city.isNotEmpty)
      .toList();
}

int _locationCountOf(List<BrandPlace>? places) {
  if (places == null || places.isEmpty) return 0;
  return places.fold<int>(0, (sum, place) => sum + place.count);
}

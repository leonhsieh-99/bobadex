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

class Brand {
  final String slug;
  final String display;
  final List<BrandAlias> aliases;
  final String? iconPath;
  BrandStatus status;
  final String? website;

  Brand({
    required this.slug,
    required this.display,
    List<BrandAlias>? aliases,
    this.iconPath,
    this.status = BrandStatus.active,
    this.website,
  }) : aliases = aliases ?? [];

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
    };
  }
}

List<BrandAlias> _parseAliases(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map(BrandAlias.fromJson).toList();
}

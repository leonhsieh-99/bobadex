class BrandProfile {
  final String? publicSummary;
  final String? locationLabel;
  final int? foundedYear;
  final String? website;
  final List<String> knownFor;

  const BrandProfile({
    this.publicSummary,
    this.locationLabel,
    this.foundedYear,
    this.website,
    this.knownFor = const [],
  });

  bool get hasAbout => publicSummary != null && publicSummary!.trim().isNotEmpty;
  bool get hasChips =>
      locationLabel != null || foundedYear != null || (website != null && website!.isNotEmpty);
  bool get hasContent => hasAbout || hasChips || knownFor.isNotEmpty;

  factory BrandProfile.fromJson(
    Map<String, dynamic>? json, {
    String? websiteFallback,
  }) {
    if (json == null) {
      return BrandProfile(website: _cleanUrl(websiteFallback));
    }

    final factsRaw = json['profile_facts'];
    final facts = factsRaw is Map ? Map<String, dynamic>.from(factsRaw) : const <String, dynamic>{};

    final signatures = _stringList(facts['signature_products']);
    final categories = _stringList(facts['product_categories']).map(_humanizeLabel).toList();
    final knownFor = (signatures.isNotEmpty ? signatures : categories).take(3).toList();

    return BrandProfile(
      publicSummary: _cleanText(json['public_summary'] as String?),
      locationLabel: _locationLabel(facts),
      foundedYear: _foundedYear(facts['founded_year']),
      website: _cleanUrl(websiteFallback) ?? _cleanUrl(facts['official_website'] as String?),
      knownFor: knownFor,
    );
  }
}

String? _cleanText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String? _cleanUrl(String? value) {
  final trimmed = _cleanText(value);
  if (trimmed == null) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) return trimmed;
  return 'https://$trimmed';
}

int? _foundedYear(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

String? _locationLabel(Map<String, dynamic> facts) {
  final founded = _cleanText(facts['founded_place'] as String?);
  if (founded != null) return founded;

  final markets = _stringList(facts['markets']);
  if (markets.isNotEmpty) return markets.first;

  final presence = facts['market_presence'];
  if (presence is List && presence.isNotEmpty) {
    final first = presence.first;
    if (first is Map && first['name'] is String) {
      return _cleanText(first['name'] as String);
    }
  }
  return null;
}

String _humanizeLabel(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.contains('_')) return trimmed;
  return trimmed
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

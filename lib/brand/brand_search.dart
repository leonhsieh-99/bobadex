import 'dart:math' as math;

import 'package:bobadex/models/brand.dart';

class BrandSearchResult {
  const BrandSearchResult({
    required this.brand,
    this.placeLine,
    this.aliasLine,
  });

  final Brand brand;
  final String? placeLine;
  final String? aliasLine;
}

List<BrandSearchResult> searchBrands(
  List<Brand> brands,
  String rawQuery, {
  double? latitude,
  double? longitude,
}) {
  final query = rawQuery.toLowerCase().trim();
  if (query.length < 2) return const [];

  final matches = brands
      .where(
        (brand) => brand.status.isActive && brandMatchesSearch(brand, query),
      )
      .toList();
  matches.sort((a, b) {
    final rank = brandMatchRank(a, query).compareTo(brandMatchRank(b, query));
    if (rank != 0) return rank;
    final distance = _compareDistance(a, b, latitude, longitude);
    if (distance != 0) return distance;
    return a.display.toLowerCase().compareTo(b.display.toLowerCase());
  });
  return _withPlaceLines(matches, query, latitude, longitude);
}

bool brandMatchesSearch(Brand brand, String query) {
  if (brand.matchesQuery(query)) return true;
  final place = mentionedPlace(brand, query);
  if (place == null) return false;
  final remainder = _withoutCity(query, place.city);
  if (remainder.isEmpty) return true;
  return brand.matchesQuery(remainder);
}

int brandMatchRank(Brand brand, String query) {
  if (brand.matchesQuery(query)) return brand.matchRank(query);
  final place = mentionedPlace(brand, query);
  if (place == null) return 5;
  final remainder = _withoutCity(query, place.city);
  if (remainder.isEmpty) return 4;
  return brand.matchRank(remainder);
}

BrandPlace? mentionedPlace(Brand brand, String query) {
  BrandPlace? best;
  for (final place in brand.places) {
    final city = place.city.toLowerCase();
    if (city.length < 3 || !query.contains(city)) continue;
    if (best == null || city.length > best.city.length) best = place;
  }
  return best;
}

String? brandPlaceLine(
  Brand brand,
  String query, {
  BrandPlace? lead,
  double? latitude,
  double? longitude,
}) {
  final places = brand.places.where((place) => place.city.isNotEmpty).toList();
  if (places.isEmpty) return null;
  final chosen =
      lead ??
      mentionedPlace(brand, query) ??
      _nearestPlace(brand, latitude, longitude) ??
      places.first;
  final others = places.where((place) => place.key != chosen.key).toList();
  final locationCount = brand.locationCount == 0
      ? places.fold<int>(0, (sum, place) => sum + place.count)
      : brand.locationCount;

  if (mentionedPlace(brand, query)?.key == chosen.key && others.isNotEmpty) {
    if (locationCount >= 4 || places.length >= 4) {
      return '${chosen.label} · $locationCount locations';
    }
    final also = others.map((place) => place.city).join(', ');
    return '${chosen.label} · also $also';
  }
  if (places.length == 1) return chosen.label;
  if (locationCount >= 4 || places.length >= 4) {
    return '${chosen.label} · $locationCount locations';
  }
  final ordered = [chosen, ...others];
  final states = ordered.map((place) => place.state).toSet();
  if (states.length == 1 && chosen.state.isNotEmpty) {
    return '${ordered.map((place) => place.city).join(' · ')}, ${chosen.state}';
  }
  return ordered.map((place) => place.label).join(' · ');
}

List<BrandSearchResult> _withPlaceLines(
  List<Brand> matches,
  String query,
  double? latitude,
  double? longitude,
) {
  final groups = <String, List<Brand>>{};
  for (final brand in matches) {
    groups.putIfAbsent(brand.display.toLowerCase(), () => []).add(brand);
  }

  final leads = <Brand, BrandPlace?>{};
  for (final group in groups.values) {
    final used = <String>{};
    for (final brand in group) {
      final shared = <String>{
        for (final other in group)
          if (other.slug != brand.slug)
            for (final place in other.places) place.key,
      };
      final preferred = _leadCandidates(
        brand,
        query,
        latitude,
        longitude,
        shared,
      );
      BrandPlace? lead;
      for (final place in preferred) {
        if (used.contains(place.key)) continue;
        lead = place;
        break;
      }
      lead ??= preferred.isEmpty ? null : preferred.first;
      if (lead != null) used.add(lead.key);
      leads[brand] = lead;
    }
  }

  return [
    for (final brand in matches)
      BrandSearchResult(
        brand: brand,
        placeLine: brandPlaceLine(
          brand,
          query,
          lead: leads[brand],
          latitude: latitude,
          longitude: longitude,
        ),
        aliasLine: brand.matchingAliasLabel(query),
      ),
  ];
}

List<BrandPlace> _leadCandidates(
  Brand brand,
  String query,
  double? latitude,
  double? longitude,
  Set<String> sharedKeys,
) {
  final places = [...brand.places.where((place) => place.city.isNotEmpty)];
  final mentioned = mentionedPlace(brand, query);
  final nearest = _nearestPlace(brand, latitude, longitude);
  places.sort((a, b) {
    if (mentioned != null) {
      if (a.key == mentioned.key) return -1;
      if (b.key == mentioned.key) return 1;
    }
    final aShared = sharedKeys.contains(a.key);
    final bShared = sharedKeys.contains(b.key);
    if (aShared != bShared) return aShared ? 1 : -1;
    if (nearest != null) {
      if (a.key == nearest.key) return -1;
      if (b.key == nearest.key) return 1;
    }
    final count = b.count.compareTo(a.count);
    if (count != 0) return count;
    return a.city.compareTo(b.city);
  });
  return places;
}

int _compareDistance(Brand a, Brand b, double? latitude, double? longitude) {
  final aDistance = _nearestKm(a, latitude, longitude);
  final bDistance = _nearestKm(b, latitude, longitude);
  if (aDistance == null && bDistance == null) return 0;
  if (aDistance == null) return 1;
  if (bDistance == null) return -1;
  return aDistance.compareTo(bDistance);
}

double? _nearestKm(Brand brand, double? latitude, double? longitude) {
  final place = _nearestPlace(brand, latitude, longitude);
  if (place == null ||
      latitude == null ||
      longitude == null ||
      place.latitude == null ||
      place.longitude == null) {
    return null;
  }
  return _km(latitude, longitude, place.latitude!, place.longitude!);
}

BrandPlace? _nearestPlace(Brand brand, double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return null;
  BrandPlace? best;
  var bestKm = double.infinity;
  for (final place in brand.places) {
    if (place.latitude == null || place.longitude == null) continue;
    final km = _km(latitude, longitude, place.latitude!, place.longitude!);
    if (km < bestKm) {
      best = place;
      bestKm = km;
    }
  }
  return best;
}

String _withoutCity(String query, String city) {
  return query
      .replaceAll(city.toLowerCase(), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double _km(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _rad(double degrees) => degrees * math.pi / 180;

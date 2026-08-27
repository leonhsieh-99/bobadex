import 'package:bobadex/helpers/brand_cache_store.dart';
import 'package:bobadex/helpers/retry_helper.dart';
import 'package:collection/collection.dart';
import '../models/brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BrandState extends ChangeNotifier {
  final List<Brand> _brands = [];
  Map<String, String> nameLookup = {};
  bool _hasError = false;

  List<Brand> get all => _brands;
  bool get hasError => _hasError;

  final _cache = BrandCacheStore();
  // v2: aliases live on brand_aliases, not brands.aliases
  static const _cacheVersion = 'v2';

  Brand? getBrand(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    return _brands.firstWhereOrNull((b) => b.slug == slug);
  }

  String getName(String slug) {
    if (slug.isEmpty) return '';
    return nameLookup[slug] ?? slug;
  }

  List<Brand> search(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    if (query.length < 2) return const [];

    final matches = _brands
        .where((b) => b.status.isActive && b.matchesQuery(query))
        .toList();
    matches.sort((a, b) {
      final rank = a.matchRank(query).compareTo(b.matchRank(query));
      if (rank != 0) return rank;
      return a.display.toLowerCase().compareTo(b.display.toLowerCase());
    });
    return matches;
  }

  void addBrand(Brand brand) {
    _brands.add(brand);
    notifyListeners();
  }
  
  void reset() {
    _brands.clear();
    notifyListeners();
  }

  Future<void> loadFromSupabase({bool forceRefresh = false}) async {
    final supabase = Supabase.instance.client;

    // determine current scope
    final isReviewer = (supabase.auth.currentUser?.appMetadata['role'] == 'reviewer');
    final dataKey = isReviewer
        ? 'brands_demo_$_cacheVersion'
        : 'brands_public_$_cacheVersion';
    final timeKey = '${dataKey}_last_updated';

    // 1) Warm from scope-specific cache
    final cachedData = await _cache.get(dataKey);
    final cachedLastUpdatedStr = await _cache.get(timeKey) as String?;
    final cachedLastUpdated = cachedLastUpdatedStr != null
        ? DateTime.tryParse(cachedLastUpdatedStr)
        : null;

    if (!forceRefresh && cachedData != null && _brands.isEmpty) {
      final cachedBrands = (cachedData as List)
          .map((json) => Brand.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _brands
        ..clear()
        ..addAll(cachedBrands.where((b) => b.status.isActive));
      _updateNameLookup();
      notifyListeners();
      debugPrint('Loaded ${_brands.length} brands from cache [$dataKey]');
    }

    try {
      // 2) Server version (global)
      final versionRow = await RetryHelper.retry(() => supabase
          .from('brand_metadata')
          .select('last_updated')
          .eq('id', 1)
          .maybeSingle());

      final serverLastUpdated = versionRow != null
          ? DateTime.tryParse(versionRow['last_updated'] as String)
          : null;

      final needsUpdate = forceRefresh ||
          serverLastUpdated == null ||
          cachedLastUpdated == null ||
          serverLastUpdated.isAfter(cachedLastUpdated);

      // IMPORTANT: also refresh if scope changed vs what’s currently loaded
      final currentScopeLoaded =
          (nameLookup.isNotEmpty && await _cache.get('current_scope') == (isReviewer ? 'demo' : 'public'));
      final shouldFetch = needsUpdate || !currentScopeLoaded;

      if (!shouldFetch) {
        debugPrint('Cache up to date for scope [$dataKey]. No fetch.');
        return;
      }

      // 3) Fetch catalog columns only. Enrichment fields on brands stay server-side.
      final rows = await RetryHelper.retry(() => supabase
          .from('brands')
          .select('slug, display, icon_path, status, brand_aliases(*)')
          .order('slug'));

      final freshBrands = (rows as List).map<Brand>((json) => Brand.fromJson(json)).toList();

      _brands
        ..clear()
        ..addAll(freshBrands.where((b) => b.status.isActive));
      _updateNameLookup();
      notifyListeners();
      debugPrint('Loaded ${_brands.length} brands from Supabase [scope=$dataKey]');

      // 4) Persist cache + timestamp + scope marker
      await _cache.putAll({
        dataKey: freshBrands.map((b) => b.toJson()).toList(),
        if (serverLastUpdated != null) timeKey: serverLastUpdated.toIso8601String(),
        'current_scope': isReviewer ? 'demo' : 'public',
      });
    } catch (e) {
      if (!_hasError) {
        _hasError = true;
        notifyListeners();
      }
      debugPrint('Error loading brands: $e');
    }
  }

  void _updateNameLookup() {
    nameLookup = {for (var brand in _brands) brand.slug: brand.display};
  }
}

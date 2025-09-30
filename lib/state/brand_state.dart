import 'package:bobadex/helpers/retry_helper.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BrandState extends ChangeNotifier {
  final List<Brand> _brands = [];
  Map<String, String> nameLookup = {};
  bool _hasError = false;

  List<Brand> get all => _brands;
  bool get hasError => _hasError;

  static const _cacheBox = 'brand_cache';

  Brand? getBrand(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    return _brands.firstWhereOrNull((b) => b.slug == slug);
  }

  String getName(String slug) {
    if (slug.isEmpty) return "";
    return nameLookup[slug]!;
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
    final cacheBox = await Hive.openBox(_cacheBox);

    // determine current scope
    final isReviewer = (supabase.auth.currentUser?.appMetadata['role'] == 'reviewer');
    print(supabase.auth.currentUser!.id);
    print((supabase.auth.currentUser?.appMetadata['role']));
    final dataKey = isReviewer ? 'brands_demo' : 'brands_public';
    final timeKey = '${dataKey}_last_updated';

    // 1) Warm from scope-specific cache
    final cachedData = cacheBox.get(dataKey);
    final cachedLastUpdatedStr = cacheBox.get(timeKey) as String?;
    final cachedLastUpdated = cachedLastUpdatedStr != null
        ? DateTime.tryParse(cachedLastUpdatedStr)
        : null;

    if (!forceRefresh && cachedData != null && _brands.isEmpty) {
      final cachedBrands = (cachedData as List)
          .map((json) => Brand.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      _brands
        ..clear()
        ..addAll(cachedBrands.where((b) => b.status == BrandStatus.active));
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
          (nameLookup.isNotEmpty && cacheBox.get('current_scope') == (isReviewer ? 'demo' : 'public'));
      final shouldFetch = needsUpdate || !currentScopeLoaded;

      if (!shouldFetch) {
        debugPrint('Cache up to date for scope [$dataKey]. No fetch.');
        return;
      }

      // 3) Fetch fresh list (RLS will return only the allowed scope)
      final rows = await RetryHelper.retry(() => supabase
          .from('brands')
          .select('*')
          .order('slug'));

      final freshBrands = (rows as List).map<Brand>((json) => Brand.fromJson(json)).toList();

      _brands
        ..clear()
        ..addAll(freshBrands.where((b) => b.status == BrandStatus.active));
      _updateNameLookup();
      notifyListeners();
      debugPrint('Loaded ${_brands.length} brands from Supabase [scope=$dataKey]');

      // 4) Persist cache + timestamp + scope marker
      await cacheBox.put(dataKey, freshBrands.map((b) => b.toJson()).toList());
      if (serverLastUpdated != null) {
        await cacheBox.put(timeKey, serverLastUpdated.toIso8601String());
      }
      await cacheBox.put('current_scope', isReviewer ? 'demo' : 'public');
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
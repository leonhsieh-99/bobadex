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

    // 1) Warm from cache
    final cachedData = cacheBox.get('brands');
    final cachedLastUpdatedStr = cacheBox.get('brands_last_updated') as String?;
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
      debugPrint('Loaded ${_brands.length} brands from cache');
    }

    try {
      // 2) Get server version
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

      if (!needsUpdate) {
        debugPrint('Cache is up to date. No fetch needed');
        return;
      }

      // 3) Fetch fresh list
      final rows = await RetryHelper.retry(() => supabase
          .from('brands')
          .select('*')
          .order('slug'));

      final freshBrands =
          (rows as List).map<Brand>((json) => Brand.fromJson(json)).toList();

      _brands
        ..clear()
        ..addAll(freshBrands.where((b) => b.status == BrandStatus.active));
      _updateNameLookup();
      notifyListeners();
      debugPrint('Loaded ${_brands.length} brands from Supabase');

      // 4) Persist cache + SERVER timestamp
      await cacheBox.put('brands', freshBrands.map((b) => b.toJson()).toList());
      if (serverLastUpdated != null) {
        await cacheBox.put('brands_last_updated', serverLastUpdated.toIso8601String());
      }
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
import 'package:collection/collection.dart';

import '../models/brand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class BrandState extends ChangeNotifier {
  final List<Brand> _brands = [];
  Map<String, String> nameLookup = {};

  List<Brand> get all => _brands;

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

  Future<void> loadFromSupabase() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase.from('brands').select();
        _brands
        ..clear()
        ..addAll(
          response.map<Brand>((json) => Brand.fromJson(json))
        );
      nameLookup = {for (var brand in _brands) brand.slug: brand.display};
      notifyListeners();
      debugPrint('Loaded ${all.length} brands');
    } catch (e) {
      debugPrint('Error loading brands: $e');
    }
  }
}
import 'dart:async';
import 'dart:convert';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/widgets/add_new_brand_dialog.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';

class AddShopSearchPage extends StatefulWidget {
  final void Function(Brand)? onBrandSelected;
  final String? existingShopId;

  const AddShopSearchPage({super.key, this.onBrandSelected, this.existingShopId});

  @override
  State<AddShopSearchPage> createState() => _AddShopSearchPageState();
}

class _AddShopSearchPageState extends State<AddShopSearchPage> {
  final _searchController = SearchController();
  List<Brand> _filteredBrands = [];
  Timer? _debounce;

  List<Brand> get _brands {
    return context.read<BrandState>().all;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }


  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      String query = _searchController.text.toLowerCase().trim();
      if (query.length >= 2) {
        setState(() {
          _filteredBrands = _brands
              .where((b) => b.display.toLowerCase().contains(query))
              .toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleBrandTap(Brand brand) {
    if (widget.onBrandSelected != null) {
      widget.onBrandSelected!(brand);
      Navigator.pop(context);
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => BrandDetailsPage(brand: brand)
      ));
    }
  }

  Future<String?> requestBrand(String name, String city, String state) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'request-brand',
        body: {'name': name, 'city': city, 'state': state},
      );

      // Only 2xx reaches here. Treat anything not explicit "ok" as unexpected.
      final data = res.data;
      if (data is Map<String, dynamic> && data['status'] == 'ok') {
        return null; // success
      }
      return 'Unexpected server response.';
    } on FunctionException catch (e) {
      // Non-2xx landed here. Try to parse the JSON payload for details.
      Map<String, dynamic>? details;
      final raw = e.details;
      if (raw is Map<String, dynamic>) {
        details = raw;
      } else if (raw is String) {
        try {
          final decoded = json.decode(raw);
          if (decoded is Map<String, dynamic>) details = decoded;
        } catch (_) {}
      }

      final statusStr = details?['status'] as String?;
      final message   = details?['message'] as String?;
      final dupsNum   = (details?['duplicates'] as num?)?.toInt();

      if (e.status == 401) return 'Please sign in to request a brand.';
      if (e.status == 403) return 'You don’t have permission to do that.';

      if (e.status == 409) {
        if (statusStr == 'duplicate') {
          return message ?? 'Brand already exists.';
        }
        if (statusStr == 'pending') {
          if (dupsNum != null) {
            return message != null
                ? '$message ($dupsNum requests)'
                : 'A similar brand is already pending review ($dupsNum requests).';
          }
          return message ?? 'A similar brand is already pending review.';
        }
        return message ?? 'Brand already requested or exists.';
      }

      if (e.status == 422) {
        return message ?? 'Invalid request.';
      }

      // Fallback
      return message ?? 'Request failed (${e.status}).';
    } catch (_) {
      return 'Failed to request brand';
    }
  }

  void _handleAddNewBrand() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AddNewBrandDialog(
        onSubmit: (name, city) => requestBrand(name, city.name, city.state),
      ),
    );
    if (!mounted) return;
    if (result == 'success') {
      notify('Brand pending for review', SnackType.info);
    } else if (result != null) {
      notify(result, SnackType.error); // error message
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<ShopState>();
    return Scaffold(
      appBar: AppBar(title: Text('Select Shop Brand')),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search for a boba shop or brand'
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBrands.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    leading: const Icon(Icons.outlined_flag),
                    title: const Text('Request a new brand', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Not in the list? Send a request.'),
                    onTap: _handleAddNewBrand,
                  );
                }
                final brand = _filteredBrands[i - 1];
                return ListTile(
                  title: Text(brand.display),
                  trailing: CircleAvatar(
                    child: shopState.shopsForCurrentUser().map((s) => s.brandSlug).contains(brand.slug)
                      ? Icon(Icons.check)
                      : Icon(Icons.add)
                  ),
                  onTap: () => _handleBrandTap(brand)
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

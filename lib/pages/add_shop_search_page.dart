import 'dart:async';

import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/notification_queue.dart';
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

  Future<String?> verifyBrand(String brand, String city, String state) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'verify-brand',
        body: {
          'name': brand,
          'city': city,
          'state': state,
          'user_id': userId,
        },
      );

      final status = res.status;
      final data = res.data as Map<String, dynamic>?;

      if (status == 200 && data != null) {
        final apiStatus = data['status'];
        if (apiStatus == 'ok') {
          return null; // No error, success
        } else if (apiStatus == 'rejected') {
          return data['message'] ?? 'Could not verify shop.';
        } else {
          // Any other "status" (like duplicate, pending, etc)
          return data['message'] ?? 'Something went wrong';
        }
      } else if (status == 409 && data != null) {
        // Duplicate or pending
        return data['message'] ?? 'Duplicate or pending brand';
      } else if (status == 422 && data != null) {
        return 'This brand could not be verified';
      } else if (data != null && data['error'] != null) {
        return data['error'];
      } else {
        return 'Unknown error occurred. (${res.status})';
      }
    } catch (e) {
      return 'Failed to verify brand: $e';
    }
  }

  void _handleAddNewBrand() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AddNewBrandDialog(
        onSubmit: (name, city) => verifyBrand(name, city.name, city.state),
      ),
    );
    if (!mounted) return;
    if (result == 'success') {
      context.read<NotificationQueue>().queue('Brand pending for review', SnackType.info);
    } else if (result != null) {
      context.read<NotificationQueue>().queue(result, SnackType.error); // error message
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
                    title: Text('Submit new brand',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                    leading: Icon(Icons.add),
                    onTap: () => _handleAddNewBrand()
                  );
                }
                final brand = _filteredBrands[i - 1];
                return ListTile(
                  title: Text(brand.display),
                  trailing: CircleAvatar(
                    child: shopState.all.map((s) => s.brandSlug).contains(brand.slug)
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

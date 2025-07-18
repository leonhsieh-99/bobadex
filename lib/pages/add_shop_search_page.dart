import 'package:bobadex/helpers/show_snackbar.dart';
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

  List<Brand> get _brands {
    return context.read<BrandState>().all;
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSearchChanged());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onSearchChanged();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBrands = _brands
          .where((b) => b.display.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _handleAddNewBrand() async {
    await showDialog(
      context: context,
      builder: (_) => AddNewBrandDialog(onSubmit: (name, location) async {
        try {
          await Supabase.instance.client
            .from('brand_staging')
            .insert({
              'suggested_name': name,
              'location': location,
              'submitted_by': Supabase.instance.client.auth.currentUser!.id,
              'status': 'pending',
            });
          if (mounted) showAppSnackBar(context, 'Brand pending for review');
        } catch (e) {
          debugPrint('Error submitting new shop $e');
          if (mounted) showAppSnackBar(context, 'Error submitting new shop', type: SnackType.error);
        }
      })
    );
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

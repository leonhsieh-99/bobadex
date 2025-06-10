import 'package:bobadex/state/shop_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/brand_state.dart';
import '../models/brand.dart';
import '../widgets/add_edit_shop_dialog.dart';

class AddShopSearchPage extends StatefulWidget {
  final void Function(Brand)? onBrandSelected;
  final String? existingShopId;

  const AddShopSearchPage({super.key, this.onBrandSelected, this.existingShopId});

  @override
  State<AddShopSearchPage> createState() => _AddShopSearchPageState();
}

class _AddShopSearchPageState extends State<AddShopSearchPage> {
  final TextEditingController _searchController = TextEditingController();
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

  void _handleBrandTap(Brand? brand) {
    if (widget.onBrandSelected != null) {
      widget.onBrandSelected!(brand!);
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder: (context) => AddOrEditShopDialog(
          onSubmit: (shop) {
            context.read<ShopState>().add(shop);
            Navigator.of(context).pop();
          },
          brand: brand!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Shop Brand')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'Search for a boba shop brand...',
                  prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBrands.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    title: Text('Add custom shop/brand',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    leading: Icon(Icons.add),
                    onTap: () => _handleBrandTap(null)
                  );
                }
                final brand = _filteredBrands[i - 1];
                return ListTile(
                  title: Text(brand.display),
                  trailing: CircleAvatar(
                    child: Icon(Icons.add),
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

import 'dart:async';
import 'package:bobadex/brand/brand_search.dart';
import 'package:bobadex/brand/brand_request.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/widgets/add_new_brand_dialog.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:bobadex/widgets/custom_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';

class AddShopSearchPage extends StatefulWidget {
  final void Function(Brand)? onBrandSelected;
  final String? existingShopId;
  final bool embedded;

  const AddShopSearchPage({
    super.key,
    this.onBrandSelected,
    this.existingShopId,
    this.embedded = false,
  });

  @override
  State<AddShopSearchPage> createState() => _AddShopSearchPageState();
}

class _AddShopSearchPageState extends State<AddShopSearchPage> {
  final _searchController = SearchController();
  List<BrandSearchResult> _results = [];
  Timer? _debounce;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadOrigin();
  }

  Future<void> _loadOrigin() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      final position =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 8),
            ),
          );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      _onSearchChanged(immediate: true);
    } catch (_) {}
  }

  void _onSearchChanged({bool immediate = false}) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    void run() {
      if (!mounted) return;
      final query = _searchController.text;
      setState(() {
        _results = context.read<BrandState>().search(
          query,
          latitude: _latitude,
          longitude: _longitude,
        );
      });
    }

    if (immediate) {
      run();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), run);
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)),
      );
    }
  }

  Future<String?> requestBrand(BrandRequestDraft draft) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    return submitBrandRequest(
      draft: draft,
      signedIn: signedIn,
      invoke: (body) async {
        try {
          final res = await Supabase.instance.client.functions.invoke(
            'request-brand',
            body: body,
          );
          return BrandRequestHttp(
            status: res.status,
            body: brandRequestBodyFromUnknown(res.data),
          );
        } on FunctionException catch (e) {
          return BrandRequestHttp(
            status: e.status,
            body: brandRequestBodyFromUnknown(e.details),
          );
        }
      },
    );
  }

  void _handleAddNewBrand() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AddNewBrandDialog(onSubmit: requestBrand),
    );
    if (!mounted) return;
    if (result == 'success') {
      notify(brandRequestPendingMessage, SnackType.info);
    } else if (result != null) {
      notify(result, SnackType.error); // error message
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownedSlugs = context.select<ShopState, Set<String?>>(
      (s) => s.shopsForCurrentUser().map((shop) => shop.brandSlug).toSet(),
    );
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Select Shop Brand')),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search for a boba shop or brand',
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return ListTile(
                    leading: const Icon(Icons.outlined_flag),
                    title: const Text(
                      'Request a new brand',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Not in the list? Send a request.'),
                    onTap: _handleAddNewBrand,
                  );
                }
                final result = _results[i - 1];
                final brand = result.brand;
                final lines = [
                  if (result.placeLine != null) result.placeLine!,
                  if (result.aliasLine != null)
                    'Also known as ${result.aliasLine}',
                ];
                final owned = ownedSlugs.contains(brand.slug);
                return ListTile(
                  leading: BrandMark(
                    name: brand.display,
                    slug: brand.slug,
                    iconPath: brand.iconPath,
                    size: 40,
                  ),
                  title: Text(brand.display),
                  isThreeLine: lines.length > 1,
                  subtitle: lines.isEmpty
                      ? null
                      : Text(lines.join('\n'), maxLines: 2),
                  trailing: owned
                      ? const BobaChip(label: 'In dex ✓', selected: true)
                      : const Icon(Icons.add),
                  onTap: () => _handleBrandTap(brand),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

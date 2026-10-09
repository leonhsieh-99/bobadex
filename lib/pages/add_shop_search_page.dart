import 'dart:async';
import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/brand/brand_request.dart';
import 'package:bobadex/brand/brand_search.dart';
import 'package:bobadex/helpers/save_shop_visit.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/widgets/add_edit_shop_dialog.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/boba_search_field.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/add_new_brand_dialog.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/brand.dart';

class AddShopSearchPage extends StatefulWidget {
  final void Function(Brand)? onBrandSelected;
  final String? existingShopId;
  final bool embedded;
  final bool pickOnly;
  final bool showAddBrand;

  const AddShopSearchPage({
    super.key,
    this.onBrandSelected,
    this.existingShopId,
    this.embedded = false,
    this.pickOnly = false,
    this.showAddBrand = true,
  });

  @override
  State<AddShopSearchPage> createState() => _AddShopSearchPageState();
}

class _AddShopSearchPageState extends State<AddShopSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<BrandSearchResult> _results = [];
  Timer? _debounce;
  String _query = '';
  double? _latitude;
  double? _longitude;
  bool _originReady = false;

  bool get _searching => _query.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _loadOrigin();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _loadOrigin() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      final permission = enabled ? await Geolocator.checkPermission() : null;
      final allowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (enabled && allowed && mounted) {
        final position =
            await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 8),
              ),
            );
        if (mounted) {
          _latitude = position.latitude;
          _longitude = position.longitude;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _originReady = true;
      final query = _query.trim();
      if (query.length >= 2) {
        _results = context.read<BrandState>().search(
          query,
          latitude: _latitude,
          longitude: _longitude,
        );
      }
    });
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      setState(() {
        _query = value;
        _results = const [];
      });
      return;
    }
    setState(() => _query = value);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _results = context.read<BrandState>().search(
          query,
          latitude: _latitude,
          longitude: _longitude,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _quickAdd(Brand brand) async {
    final shopState = context.read<ShopState>();
    final achievements = context.read<AchievementsState>();
    final analytics = context.read<AnalyticsService>();
    await AddOrEditShopDialog.show(
      context,
      brand: brand,
      onSubmit: (submittedShop) async {
        try {
          return await saveShopVisit(
            shop: submittedShop,
            isNew: true,
            shopState: shopState,
            achievements: achievements,
            analytics: analytics,
          );
        } catch (e, st) {
          debugPrint('error in quick add: $e');
          debugPrintStack(stackTrace: st);
          notify('Failed to add shop', SnackType.error);
          return Future.error(e);
        }
      },
    );
  }

  void _handleBrandTap(Brand brand) {
    if (widget.pickOnly) {
      Navigator.pop(context, brand);
      return;
    }
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

  Future<void> _handleAddNewBrand() async {
    final query = _query.trim();
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => AddNewBrandDialog(
        onSubmit: requestBrand,
        initialName: query.length >= 2 ? query : null,
      ),
    );
    if (!mounted) return;
    if (result == 'success') {
      notify(brandRequestPendingMessage, SnackType.info);
    } else if (result != null) {
      notify(result, SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogCount = context.select<BrandState, int>((s) => s.all.length);
    final owned = context.select<ShopState, Map<String, double>>((s) {
      final ratings = <String, double>{};
      for (final shop in s.shopsForCurrentUser()) {
        final slug = shop.brandSlug;
        if (slug != null && slug.isNotEmpty) ratings[slug] = shop.rating;
      }
      return ratings;
    });
    final searching = _searching;
    final latitude = _latitude;
    final longitude = _longitude;
    final nearby =
        !searching &&
            _originReady &&
            catalogCount > 0 &&
            latitude != null &&
            longitude != null
        ? context.read<BrandState>().nearby(
            latitude: latitude,
            longitude: longitude,
          )
        : const <BrandSearchResult>[];
    final showRequestFooter =
        widget.showAddBrand &&
        searching &&
        _results.isNotEmpty &&
        _results.length <= 3;
    final mode = !searching
        ? 'browse'
        : _results.isEmpty
        ? 'empty'
        : 'results';

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(widget.pickOnly ? 'Find a brand' : 'Add to your dex'),
            ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BobaSpace.x4,
                BobaSpace.x2,
                BobaSpace.x4,
                BobaSpace.x2,
              ),
              child: BobaSearchField(
                controller: _searchController,
                focusNode: _focusNode,
                hint: 'Search brands',
                onChanged: _onQueryChanged,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: BobaMotion.fast,
                child: KeyedSubtree(
                  key: ValueKey(mode),
                  child: !searching
                      ? _BrowseBody(
                          ready: _originReady,
                          pickOnly: widget.pickOnly,
                          nearby: nearby,
                          owned: owned,
                          onBrandTap: _handleBrandTap,
                        )
                      : _results.isEmpty
                      ? _EmptyResults(
                          query: _query.trim(),
                          canRequest: widget.showAddBrand,
                          onRequest: _handleAddNewBrand,
                        )
                      : _ResultList(
                          results: _results,
                          owned: owned,
                          onBrandTap: _handleBrandTap,
                          onAdd:
                              widget.pickOnly || widget.onBrandSelected != null
                              ? null
                              : _quickAdd,
                        ),
                ),
              ),
            ),
            if (showRequestFooter)
              _RequestFooter(
                query: _query.trim(),
                onRequest: _handleAddNewBrand,
              ),
          ],
        ),
      ),
    );
  }
}

class _BrowseBody extends StatelessWidget {
  const _BrowseBody({
    required this.ready,
    required this.pickOnly,
    required this.nearby,
    required this.owned,
    required this.onBrandTap,
  });

  final bool ready;
  final bool pickOnly;
  final List<BrandSearchResult> nearby;
  final Map<String, double> owned;
  final ValueChanged<Brand> onBrandTap;

  @override
  Widget build(BuildContext context) {
    if (!ready) return const SizedBox.shrink();
    if (nearby.isEmpty) {
      return EmptyState(
        title: pickOnly ? 'Find a brand' : 'Search for a brand',
        body: pickOnly
            ? 'Search the catalog by name or city.'
            : 'Search by name or city to add a shop to your dex.',
      );
    }
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: BobaSpace.x4),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BobaSpace.x4,
            BobaSpace.x3,
            BobaSpace.x4,
            BobaSpace.x2,
          ),
          child: Text(
            'Near you',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x4),
            itemCount: nearby.length,
            separatorBuilder: (_, _) => const SizedBox(width: BobaSpace.x3),
            itemBuilder: (context, index) {
              final result = nearby[index];
              return _NearbyBrand(
                result: result,
                inDex: owned.containsKey(result.brand.slug),
                onTap: () => onBrandTap(result.brand),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NearbyBrand extends StatelessWidget {
  const _NearbyBrand({
    required this.result,
    required this.inDex,
    required this.onTap,
  });

  final BrandSearchResult result;
  final bool inDex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final place = result.placeLine;
    final caption = inDex ? 'In dex' : place;
    return SizedBox(
      width: 108,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BobaRadius.md),
        child: Column(
          children: [
            BrandMark(
              name: result.brand.display,
              slug: result.brand.slug,
              iconPath: result.brand.iconPath,
              size: BobaSize.markMd,
            ),
            const SizedBox(height: BobaSpace.x2),
            Text(
              result.brand.display,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            if (caption != null && caption.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: inDex ? tokens.accentInk : tokens.inkFaint,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.results,
    required this.owned,
    required this.onBrandTap,
    this.onAdd,
  });

  final List<BrandSearchResult> results;
  final Map<String, double> owned;
  final ValueChanged<Brand> onBrandTap;
  final ValueChanged<Brand>? onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: BobaSpace.x4),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final rating = owned[result.brand.slug];
        return _BrandRow(
          result: result,
          inDex: rating != null,
          rating: rating,
          onTap: () => onBrandTap(result.brand),
          onAdd: rating == null ? onAdd : null,
        );
      },
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.result,
    required this.inDex,
    required this.rating,
    required this.onTap,
    this.onAdd,
  });

  final BrandSearchResult result;
  final bool inDex;
  final double? rating;
  final VoidCallback onTap;
  final ValueChanged<Brand>? onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final lines = [
      if (result.placeLine != null) result.placeLine!,
      if (result.aliasLine != null) 'Also known as ${result.aliasLine}',
    ];
    final add = onAdd;
    return Padding(
      padding: const EdgeInsets.only(right: BobaSpace.x2),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BobaSpace.x4,
                  BobaSpace.x3,
                  BobaSpace.x2,
                  BobaSpace.x3,
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: BrandMark.heroTag(result.brand.slug),
                      child: BrandMark(
                        name: result.brand.display,
                        slug: result.brand.slug,
                        iconPath: result.brand.iconPath,
                        size: BobaSize.markMd,
                      ),
                    ),
                    const SizedBox(width: BobaSpace.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.brand.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          if (lines.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              lines.join('\n'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: tokens.inkMuted),
                            ),
                          ],
                          if (inDex && rating != null && rating! > 0) ...[
                            const SizedBox(height: BobaSpace.x1),
                            RatingText(
                              value: rating,
                              size: RatingTextSize.small,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (inDex)
                      const BobaChip(label: 'In dex', selected: true)
                    else if (add == null)
                      Icon(Icons.chevron_right_rounded, color: tokens.inkFaint),
                  ],
                ),
              ),
            ),
          ),
          if (add != null)
            IconButton(
              tooltip: 'Add to dex',
              onPressed: () => add(result.brand),
              icon: Icon(Icons.add_rounded, color: tokens.accent),
            ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.query,
    required this.canRequest,
    required this.onRequest,
  });

  final String query;
  final bool canRequest;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No matches',
      body: canRequest ? "Can't find $query?" : 'Try another name or city.',
      action: canRequest
          ? BobaButton(label: 'Request it', onPressed: onRequest)
          : null,
    );
  }
}

class _RequestFooter extends StatelessWidget {
  const _RequestFooter({required this.query, required this.onRequest});

  final String query;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.outline, width: BobaStroke.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BobaSpace.x4,
          BobaSpace.x2,
          BobaSpace.x2,
          BobaSpace.x2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
                  children: [
                    const TextSpan(text: "Can't find "),
                    TextSpan(
                      text: query,
                      style: TextStyle(
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            BobaButton(
              label: 'Request it',
              variant: BobaButtonVariant.tertiary,
              size: BobaButtonSize.small,
              onPressed: onRequest,
            ),
          ],
        ),
      ),
    );
  }
}

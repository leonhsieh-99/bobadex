import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/boba_progress_bar.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/components/region_seal.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CountyCollectionPage extends StatefulWidget {
  const CountyCollectionPage({super.key, required this.county});

  final CountySummary county;

  @override
  State<CountyCollectionPage> createState() => _CountyCollectionPageState();
}

class _CountyCollectionPageState extends State<CountyCollectionPage> {
  final _repo = CollectionRepository();
  final _items = <CountyBrand>[];

  String _filter = 'all';
  String _sort = 'name';
  int _eligible = 0;
  int _discovered = 0;
  int _missing = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _missingCounty = false;

  @override
  void initState() {
    super.initState();
    _eligible = widget.county.eligibleTotal;
    _discovered = widget.county.discoveredTotal;
    _missing = (_eligible - _discovered).clamp(0, _eligible);
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loadingMore || !_hasMore)) return;
    setState(() {
      if (reset) {
        _loading = true;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final detail = await _repo.countyDetail(
        countyPlaceId: widget.county.countyPlaceId,
        offset: reset ? 0 : _items.length,
        filter: _filter,
        sort: _sort,
      );
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _missingCounty = true;
        });
        return;
      }
      setState(() {
        if (reset) _items.clear();
        _items.addAll(detail.items);
        _eligible = detail.eligibleTotal;
        _discovered = detail.discoveredTotal;
        _missing = detail.undiscoveredTotal;
        _hasMore = detail.items.length == CollectionRepository.pageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('county detail failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
      notify('Could not load this county', SnackType.error);
    }
  }

  void _setFilter(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load(reset: true);
  }

  void _toggleSort() {
    setState(() => _sort = _sort == 'name' ? 'storefronts' : 'name');
    _load(reset: true);
  }

  Future<void> _untrack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove collection'),
        content: Text(
          '${widget.county.countyName} leaves your list. Brands you already logged stay in your dex.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repo.untrack(widget.county.countyPlaceId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('untrack county failed: $e');
      notify('Could not remove this county', SnackType.error);
    }
  }

  Future<void> _openBrand(CountyBrand item) async {
    final userId = context.read<UserState>().current.id;
    final shop = context.read<ShopState>().getShopByBrand(
      userId,
      item.brandSlug,
    );
    final shopId = shop?.id;
    if (item.discovered && shopId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShopDetailPage(shopId: shopId, userId: userId),
        ),
      );
    } else {
      final known = context.read<BrandState>().getBrand(item.brandSlug);
      final brand =
          known ??
          Brand(
            slug: item.brandSlug,
            display: item.display,
            iconPath: item.iconPath,
          );
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)));
    }
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final userId = context.select<UserState, String>((s) => s.current.id);
    final columns = context.select<UserState, int>(
      (s) => s.current.gridColumns.clamp(2, 3),
    );
    final fraction = _eligible == 0 ? 0.0 : _discovered / _eligible;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.county.countyName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'remove') _untrack();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove collection')),
            ],
          ),
        ],
      ),
      body: _missingCounty
          ? Center(
              child: Text(
                'This county is not open yet',
                style: context.bobaText.empty,
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      children: [
                        RegionSeal(
                          name: widget.county.countyName,
                          size: 72,
                          complete: _eligible > 0 && _discovered >= _eligible,
                        ),
                        const SizedBox(height: BobaSpace.x3),
                        Text(
                          '$_discovered / $_eligible',
                          style: context.bobaText.numeral(fontSize: 28),
                        ),
                        Text(
                          'brands collected',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: tokens.inkMuted),
                        ),
                        const SizedBox(height: BobaSpace.x3),
                        BobaProgressBar(
                          value: fraction,
                          semanticsLabel:
                              '$_missing left in ${widget.county.countyName}',
                        ),
                        if (_missing > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '$_missing left',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: tokens.inkMuted),
                            ),
                          ),
                        const SizedBox(height: BobaSpace.x4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              BobaChip(
                                label: 'All',
                                selected: _filter == 'all',
                                onTap: () => _setFilter('all'),
                              ),
                              const SizedBox(width: 8),
                              BobaChip(
                                label: 'Collected $_discovered',
                                selected: _filter == 'discovered',
                                onTap: () => _setFilter('discovered'),
                              ),
                              const SizedBox(width: 8),
                              BobaChip(
                                label: 'Missing $_missing',
                                selected: _filter == 'undiscovered',
                                onTap: () => _setFilter('undiscovered'),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _toggleSort,
                            icon: const Icon(Icons.swap_vert_rounded, size: 18),
                            label: Text(
                              _sort == 'name' ? 'Name' : 'Storefronts',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        _filter == 'discovered'
                            ? 'None collected here yet'
                            : _filter == 'undiscovered'
                            ? 'Every brand here is in your dex'
                            : 'No brands in this county yet',
                        style: context.bobaText.empty,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _items[index];
                        return _CountyBrandTile(
                          item: item,
                          userId: userId,
                          onTap: () => _openBrand(item),
                        );
                      }, childCount: _items.length),
                    ),
                  ),
                if (_hasMore && !_loading && _items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () => _load(reset: false),
                                child: const Text('Load more'),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CountyBrandTile extends StatelessWidget {
  const _CountyBrandTile({
    required this.item,
    required this.userId,
    required this.onTap,
  });

  final CountyBrand item;
  final String userId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final rating = context.select<ShopState, double?>(
      (s) => s.getShopByBrand(userId, item.brandSlug)?.rating,
    );
    final stores = item.localStorefronts == 1
        ? '1 storefront'
        : '${item.localStorefronts} known storefronts';
    return BobaCard(
      onTap: onTap,
      variant: item.discovered ? BobaCardVariant.flat : BobaCardVariant.inset,
      child: Stack(
        children: [
          // Mascot at true card center
          Center(
            child: Opacity(
              opacity: item.discovered ? 1 : 0.45,
              child: BrandMark(
                name: item.display,
                slug: item.brandSlug,
                iconPath: item.iconPath,
                size: 52,
              ),
            ),
          ),

          // Text anchored below the mascot
          Align(
            alignment: const Alignment(0, 0.55),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.display,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 20,
                    child: item.discovered
                        ? RatingText(
                            value: rating,
                            size: RatingTextSize.small,
                          )
                        : null,
                  ),
                  Text(
                    stores,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

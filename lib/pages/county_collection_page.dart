import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/collection/collection_suggestion.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/boba_button.dart';
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
  final _suggestions = <CollectionSuggestion>[];

  String _filter = 'all';
  String _sort = 'name';
  int _eligible = 0;
  int _discovered = 0;
  int _missing = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _missingCounty = false;
  bool _sendingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _eligible = widget.county.eligibleTotal;
    _discovered = widget.county.discoveredTotal;
    _missing = (_eligible - _discovered).clamp(0, _eligible);
    _load(reset: true);
    _loadSuggestions();
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

  Future<void> _loadSuggestions() async {
    try {
      final rows = await _repo.mySuggestions(widget.county.countyPlaceId);
      if (!mounted) return;
      setState(() {
        _suggestions
          ..clear()
          ..addAll(rows);
      });
    } catch (e) {
      debugPrint('collection suggestions failed: $e');
    }
  }

  bool _listed(String slug) => _items.any((item) => item.brandSlug == slug);

  Future<void> _suggestRemoval(CountyBrand item) async {
    if (hasPendingSuggestion(_suggestions, item.brandSlug, 'remove')) {
      notify(messageForCollectionSuggestion('pending'), SnackType.info);
      return;
    }
    final note = await _askReason(
      title: 'Suggest removal',
      actionLabel: 'Suggest removal',
      brandName: item.display,
    );
    if (note == null) return;
    await _submitSuggestion(
      brandSlug: item.brandSlug,
      action: 'remove',
      note: note.isEmpty ? null : note,
    );
  }

  Future<void> _missingBrand() async {
    final brand = await Navigator.of(context).push<Brand>(
      MaterialPageRoute(
        builder: (_) =>
            const AddShopSearchPage(pickOnly: true, showAddBrand: false),
      ),
    );
    if (!mounted || brand == null) return;
    if (_listed(brand.slug)) {
      notify(
        messageForCollectionSuggestion('already_in_collection'),
        SnackType.info,
      );
      return;
    }
    if (hasPendingSuggestion(_suggestions, brand.slug, 'add')) {
      notify(messageForCollectionSuggestion('pending'), SnackType.info);
      return;
    }
    final note = await _askReason(
      title: 'Suggest addition',
      actionLabel: 'Suggest addition',
      brandName: brand.display,
    );
    if (note == null) return;
    await _submitSuggestion(
      brandSlug: brand.slug,
      action: 'add',
      note: note.isEmpty ? null : note,
    );
  }

  Future<String?> _askReason({
    required String title,
    required String actionLabel,
    required String brandName,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _SuggestionReasonDialog(
        title: title,
        actionLabel: actionLabel,
        brandName: brandName,
      ),
    );
  }

  Future<void> _submitSuggestion({
    required String brandSlug,
    required String action,
    String? note,
  }) async {
    if (_sendingSuggestion) return;
    if (suggestionNoteTooLong(note ?? '')) {
      notify(
        messageForCollectionSuggestion('invalid_collection_suggestion_input'),
        SnackType.error,
      );
      return;
    }
    setState(() => _sendingSuggestion = true);
    try {
      final result = await _repo.submitSuggestion(
        countyPlaceId: widget.county.countyPlaceId,
        brandSlug: brandSlug,
        action: action,
        note: normalizeSuggestionNote(note ?? ''),
      );
      if (!mounted) return;
      notify(
        messageForCollectionSuggestion(result.status),
        collectionSuggestionIsError(result.status)
            ? SnackType.error
            : SnackType.info,
      );
      if (result.isPending) {
        setState(() {
          _suggestions.removeWhere(
            (suggestion) =>
                suggestion.brandSlug == brandSlug && suggestion.isPending,
          );
          _suggestions.insert(
            0,
            CollectionSuggestion(
              id: result.suggestionId ?? '',
              countyPlaceId: widget.county.countyPlaceId,
              brandSlug: brandSlug,
              action: action,
              status: 'pending',
              note: normalizeSuggestionNote(note ?? ''),
              submittedAt: DateTime.now(),
            ),
          );
        });
        _loadSuggestions();
      }
    } finally {
      if (mounted) setState(() => _sendingSuggestion = false);
    }
  }

  void _showSuggestionHistory() {
    final brands = context.read<BrandState>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final rows = _suggestions;
        return SafeArea(
          child: rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(BobaSpace.x6),
                  child: Text('No suggestions yet.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final suggestion = rows[index];
                    final name = brands.getName(suggestion.brandSlug);
                    final action = suggestion.action == 'remove'
                        ? 'Removal'
                        : 'Addition';
                    return ListTile(
                      title: Text(name.isEmpty ? suggestion.brandSlug : name),
                      subtitle: Text(
                        '$action · ${collectionSuggestionStatusLabel(suggestion.status)}',
                      ),
                    );
                  },
                ),
        );
      },
    );
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
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
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _items[index];
                        return _CountyBrandTile(
                          item: item,
                          userId: userId,
                          suggestionSent: hasPendingSuggestion(
                            _suggestions,
                            item.brandSlug,
                            'remove',
                          ),
                          onTap: () => _openBrand(item),
                          onSuggestRemoval: _sendingSuggestion
                              ? null
                              : () => _suggestRemoval(item),
                        );
                      }, childCount: _items.length),
                    ),
                  ),
                if (_hasMore && !_loading && _items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                if (!_loading && !_missingCounty)
                  SliverToBoxAdapter(child: _suggestionFooter(context)),
              ],
            ),
    );
  }

  Widget _suggestionFooter(BuildContext context) {
    final pendingAdds = _suggestions
        .where(
          (suggestion) => suggestion.action == 'add' && suggestion.isPending,
        )
        .toList();
    final brands = context.read<BrandState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingAdds.isNotEmpty) ...[
            Text(
              'Suggestions sent',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: BobaSpace.x2),
            for (final suggestion in pendingAdds)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  brands.getName(suggestion.brandSlug).isEmpty
                      ? suggestion.brandSlug
                      : brands.getName(suggestion.brandSlug),
                ),
                subtitle: const Text('Suggestion sent'),
              ),
            const SizedBox(height: BobaSpace.x3),
          ],
          BobaButton(
            label: 'Missing a brand?',
            variant: BobaButtonVariant.secondary,
            expanded: true,
            onPressed: _sendingSuggestion ? null : _missingBrand,
          ),
          if (_suggestions.isNotEmpty)
            BobaButton(
              label: 'Your suggestions',
              variant: BobaButtonVariant.tertiary,
              onPressed: _showSuggestionHistory,
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
    required this.suggestionSent,
    required this.onSuggestRemoval,
  });

  final CountyBrand item;
  final String userId;
  final VoidCallback onTap;
  final bool suggestionSent;
  final VoidCallback? onSuggestRemoval;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final rating = context.select<ShopState, double?>(
      (s) => s.getShopByBrand(userId, item.brandSlug)?.rating,
    );
    final stores = item.localStorefronts == 1
        ? '1 storefront'
        : '${item.localStorefronts} known storefronts';
    const mascotSize = 78.0;
    return BobaCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      variant: item.discovered ? BobaCardVariant.flat : BobaCardVariant.inset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mascotTop = constraints.maxHeight * 0.40 - mascotSize / 2;
          return Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  tooltip: 'Brand options',
                  onSelected: (value) {
                    if (value == 'remove') onSuggestRemoval?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Suggest removal'),
                    ),
                  ],
                ),
              ),
              if (suggestionSent)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 40,
                  child: Text(
                    'Suggestion sent',
                    maxLines: 2,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
                  ),
                ),
              Positioned(
                top: mascotTop,
                left: 0,
                right: 0,
                child: Center(
                  child: BrandMark(
                    name: item.display,
                    slug: item.brandSlug,
                    iconPath: item.iconPath,
                    size: mascotSize,
                    silhouette: !item.discovered,
                  ),
                ),
              ),
              Positioned(
                top: mascotTop + mascotSize + 8,
                left: 12,
                right: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: item.discovered ? null : tokens.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.discovered)
                      RatingText(value: rating, size: RatingTextSize.small),
                    Text(
                      stores,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: tokens.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuggestionReasonDialog extends StatefulWidget {
  const _SuggestionReasonDialog({
    required this.title,
    required this.actionLabel,
    required this.brandName,
  });

  final String title;
  final String actionLabel;
  final String brandName;

  @override
  State<_SuggestionReasonDialog> createState() =>
      _SuggestionReasonDialogState();
}

class _SuggestionReasonDialogState extends State<_SuggestionReasonDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.brandName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: BobaSpace.x2),
            Text(
              'A person reviews this before the collection changes.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.boba.inkMuted),
            ),
            const SizedBox(height: BobaSpace.x4),
            TextField(
              controller: _controller,
              maxLength: 500,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (suggestionNoteTooLong(_controller.text)) {
              setState(() {
                _error = messageForCollectionSuggestion(
                  'invalid_collection_suggestion_input',
                );
              });
              return;
            }
            Navigator.pop(context, _controller.text.trim());
          },
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}

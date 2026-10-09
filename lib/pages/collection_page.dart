import 'dart:async';

import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/collection/county_locator.dart';
import 'package:bobadex/helpers/app_prefs.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/county_collection_page.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/boba_search_field.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/region_card.dart';
import 'package:bobadex/ui/components/skeleton_box.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key, this.repository});

  final CollectionRepository? repository;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late final CollectionRepository _repo;
  final _locator = CountyLocator();
  late Future<List<CountySummary>> _tracked;
  CountySummary? _nearby;
  String? _placeId;
  bool _addingNearby = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? CollectionRepository();
    _tracked = _repo.trackedCounties();
    unawaited(_refreshNearby());
  }

  Future<void> _reload() async {
    final next = _repo.trackedCounties();
    setState(() {
      _tracked = next;
    });
    try {
      await next;
    } catch (e) {
      debugPrint('tracked counties failed: $e');
    }
    await _refreshNearby();
  }

  Future<void> _refreshNearby() async {
    try {
      final results = await Future.wait<Object?>([
        _repo.availableCounties(),
        AppPrefs.dismissedCountySuggestion(),
        _placeId != null
            ? Future<String?>.value(_placeId)
            : _locator.currentCountyPlaceId(_repo),
      ]);
      if (!mounted) return;
      final available = results[0] as List<CountySummary>;
      final dismissed = results[1] as String?;
      final placeId = results[2] as String?;
      if (placeId != null) _placeId = placeId;
      final match = placeId == dismissed
          ? null
          : untrackedCountyById(available, placeId);
      setState(() {
        _nearby = match;
      });
    } catch (e) {
      debugPrint('nearby county failed: $e');
    }
  }

  Future<void> _openCounty(CountySummary county) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CountyCollectionPage(county: county)),
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _addNearby() async {
    final county = _nearby;
    if (county == null || _addingNearby) return;
    setState(() => _addingNearby = true);
    try {
      await _repo.track(county.countyPlaceId);
      if (!mounted) return;
      setState(() {
        _nearby = null;
        _addingNearby = false;
      });
      await _openCounty(
        CountySummary(
          countyPlaceId: county.countyPlaceId,
          countyName: county.countyName,
          stateName: county.stateName,
          eligibleTotal: county.eligibleTotal,
          discoveredTotal: county.discoveredTotal,
          isTracked: true,
        ),
      );
    } catch (e) {
      debugPrint('track nearby county failed: $e');
      if (!mounted) return;
      setState(() => _addingNearby = false);
      notify('Could not add that county', SnackType.error);
    }
  }

  Future<void> _dismissNearby() async {
    final county = _nearby;
    if (county == null) return;
    await AppPrefs.dismissCountySuggestion(county.countyPlaceId);
    if (!mounted) return;
    setState(() => _nearby = null);
  }

  Future<void> _browse() async {
    final picked = await showModalBottomSheet<CountySummary>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BrowseCountiesSheet(repo: _repo, nearby: _nearby),
    );
    if (!mounted) return;
    if (picked == null) {
      _reload();
      return;
    }
    await _openCounty(picked);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = BobaNavBar.clearance(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect'),
        actions: [
          IconButton(
            tooltip: 'Add a county',
            onPressed: _browse,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<CountySummary>>(
        future: _tracked,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _TrackedSkeleton();
          }
          if (snapshot.hasError) {
            return EmptyState(
              title: 'Could not load collections',
              body: 'Check your connection and try again.',
              action: BobaButton(label: 'Retry', onPressed: _reload),
            );
          }
          final counties = snapshot.data ?? const <CountySummary>[];
          final nearby = _nearby;
          if (counties.isEmpty) {
            return EmptyState(
              title: nearby == null
                  ? 'Start a county collection'
                  : "You're in ${nearby.countyName}",
              body: nearby == null
                  ? 'Add the county you actually visit. Empty counties stay out of the way until you choose them.'
                  : 'Add it to start this collection. Other counties stay out of the way until you choose them.',
              action: Column(
                children: [
                  if (nearby != null) ...[
                    BobaButton(
                      label: 'Add ${nearby.countyName}',
                      expanded: true,
                      loading: _addingNearby,
                      onPressed: _addNearby,
                    ),
                    const SizedBox(height: 8),
                  ],
                  BobaButton(
                    label: 'Browse counties',
                    expanded: true,
                    variant: nearby == null
                        ? BobaButtonVariant.primary
                        : BobaButtonVariant.secondary,
                    onPressed: _browse,
                  ),
                ],
              ),
            );
          }
          final rows = nearby == null ? counties.length : counties.length + 1;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
              itemCount: rows,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (nearby != null && index == 0) {
                  return _NearbyCountyCard(
                    county: nearby,
                    adding: _addingNearby,
                    onAdd: _addNearby,
                    onDismiss: _dismissNearby,
                  );
                }
                final county = counties[nearby == null ? index : index - 1];
                return RegionCard(
                  county: county,
                  onTap: () => _openCounty(county),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BrowseCountiesSheet extends StatefulWidget {
  const _BrowseCountiesSheet({required this.repo, this.nearby});

  final CollectionRepository repo;
  final CountySummary? nearby;

  @override
  State<_BrowseCountiesSheet> createState() => _BrowseCountiesSheetState();
}

class _BrowseCountiesSheetState extends State<_BrowseCountiesSheet> {
  late Future<List<CountySummary>> _available;
  final _search = TextEditingController();
  String _query = '';
  String? _trackingId;

  @override
  void initState() {
    super.initState();
    _available = widget.repo.availableCounties();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CountySummary> _matching(List<CountySummary> counties) {
    final query = _query.trim().toLowerCase();
    final nearbyId = widget.nearby?.countyPlaceId;
    final matched = [
      for (final county in counties)
        if (query.isEmpty ||
            county.countyName.toLowerCase().contains(query) ||
            county.stateName.toLowerCase().contains(query))
          county,
    ];
    if (query.isNotEmpty || nearbyId == null) return matched;
    final nearby = matched.where((county) => county.countyPlaceId == nearbyId);
    final rest = matched.where((county) => county.countyPlaceId != nearbyId);
    return [...nearby, ...rest];
  }

  Future<void> _track(CountySummary county) async {
    if (county.isTracked) {
      Navigator.of(context).pop(county);
      return;
    }
    setState(() => _trackingId = county.countyPlaceId);
    try {
      await widget.repo.track(county.countyPlaceId);
      if (!mounted) return;
      Navigator.of(context).pop(
        CountySummary(
          countyPlaceId: county.countyPlaceId,
          countyName: county.countyName,
          stateName: county.stateName,
          eligibleTotal: county.eligibleTotal,
          discoveredTotal: county.discoveredTotal,
          isTracked: true,
        ),
      );
    } catch (e) {
      debugPrint('track county failed: $e');
      if (mounted) {
        setState(() => _trackingId = null);
        notify('Could not add that county', SnackType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = (media.size.height * 0.72)
        .clamp(
          0.0,
          media.size.height - media.viewInsets.bottom - media.padding.top,
        )
        .toDouble();
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Add a county',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: BobaSearchField(
                  controller: _search,
                  hint: 'Search counties',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<CountySummary>>(
                  future: _available,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load counties',
                          style: context.bobaText.empty,
                        ),
                      );
                    }
                    final counties = snapshot.data ?? const <CountySummary>[];
                    if (counties.isEmpty) {
                      return Center(
                        child: Text(
                          'No counties are open yet',
                          style: context.bobaText.empty,
                        ),
                      );
                    }
                    final shown = _matching(counties);
                    if (shown.isEmpty) {
                      return Center(
                        child: Text(
                          'No counties match that search',
                          style: context.bobaText.empty,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.boba.outline),
                      itemBuilder: (context, index) {
                        final county = shown[index];
                        final busy = _trackingId == county.countyPlaceId;
                        return ListTile(
                          title: Text(county.countyName),
                          subtitle: Text(
                            county.countyPlaceId == widget.nearby?.countyPlaceId
                                ? 'Near you · ${county.stateName} · ${county.eligibleTotal} brands'
                                : '${county.stateName} · ${county.eligibleTotal} brands',
                          ),
                          trailing: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : county.isTracked
                              ? Icon(
                                  Icons.check_rounded,
                                  color: context.boba.accentInk,
                                )
                              : const Icon(Icons.add_rounded),
                          onTap: _trackingId == null
                              ? () => _track(county)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyCountyCard extends StatelessWidget {
  const _NearbyCountyCard({
    required this.county,
    required this.adding,
    required this.onAdd,
    required this.onDismiss,
  });

  final CountySummary county;
  final bool adding;
  final VoidCallback onAdd;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return BobaCard(
      child: Row(
        children: [
          Icon(Icons.near_me_rounded, color: tokens.accent),
          const SizedBox(width: BobaSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  county.countyName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Near you · ${county.stateName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.inkMuted),
                ),
              ],
            ),
          ),
          BobaButton(
            label: 'Add',
            size: BobaButtonSize.small,
            loading: adding,
            onPressed: onAdd,
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: adding ? null : onDismiss,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _TrackedSkeleton extends StatelessWidget {
  const _TrackedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 88),
        SizedBox(height: 12),
        SkeletonBox(height: 88),
      ],
    );
  }
}

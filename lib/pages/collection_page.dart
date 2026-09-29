import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/collection/collection_repository.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/county_collection_page.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/region_card.dart';
import 'package:bobadex/ui/components/skeleton_box.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _repo = CollectionRepository();
  late Future<List<CountySummary>> _tracked;

  @override
  void initState() {
    super.initState();
    _tracked = _repo.trackedCounties();
  }

  Future<void> _reload() async {
    final next = _repo.trackedCounties();
    setState(() => _tracked = next);
    try {
      await next;
    } catch (e) {
      debugPrint('tracked counties failed: $e');
    }
  }

  Future<void> _openCounty(CountySummary county) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CountyCollectionPage(county: county)),
    );
    if (!mounted) return;
    _reload();
  }

  Future<void> _browse() async {
    final picked = await showModalBottomSheet<CountySummary>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BrowseCountiesSheet(repo: _repo),
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
          if (counties.isEmpty) {
            return EmptyState(
              title: 'Start a county collection',
              body:
                  'Add the county you actually visit. Empty counties stay out of the way until you choose them.',
              action: BobaButton(label: 'Browse counties', onPressed: _browse),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
              itemCount: counties.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final county = counties[index];
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
  const _BrowseCountiesSheet({required this.repo});

  final CollectionRepository repo;

  @override
  State<_BrowseCountiesSheet> createState() => _BrowseCountiesSheetState();
}

class _BrowseCountiesSheetState extends State<_BrowseCountiesSheet> {
  late Future<List<CountySummary>> _available;
  String? _trackingId;

  @override
  void initState() {
    super.initState();
    _available = widget.repo.availableCounties();
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
      notify('${county.countyName} added', SnackType.success);
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
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Add a county',
                style: Theme.of(context).textTheme.titleLarge,
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
                  return ListView.separated(
                    itemCount: counties.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: context.boba.outline),
                    itemBuilder: (context, index) {
                      final county = counties[index];
                      final busy = _trackingId == county.countyPlaceId;
                      return ListTile(
                        title: Text(county.countyName),
                        subtitle: Text(
                          '${county.stateName} · ${county.eligibleTotal} brands',
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

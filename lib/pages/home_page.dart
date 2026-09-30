import 'dart:async';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/pages/add_shop_search_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_nav_bar.dart';
import 'package:bobadex/ui/components/dex_header.dart';
import 'package:bobadex/ui/components/empty_state.dart';
import 'package:bobadex/ui/components/entry_tile.dart';
import 'package:bobadex/ui/components/skeleton_box.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/onboarding_wizard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/sortable_entry.dart';
import '../models/shop.dart';
import '../models/user.dart' as u;
import '../widgets/filter_sort_bar.dart';
import '../state/user_state.dart';
import '../state/shop_state.dart';

class HomePage extends StatefulWidget {
  final String? userId;
  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _uid;
  late final bool _isCurrentUser;
  Future<void>? _ready;
  String _searchQuery = '';
  String _selectedSort = 'favorite-desc';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authId = _signedInUserId() ?? '';
    _uid = (widget.userId?.isNotEmpty == true) ? widget.userId! : authId;
    _isCurrentUser = _uid == authId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startLoad();
    });
  }

  Future<void> _prime() async {
    final userState = context.read<UserState>();
    final shopState = context.read<ShopState>();
    final shopMediaState = context.read<ShopMediaState>();
    final futures = <Future>[
      userState.loadUser(_uid),
      shopState.loadForUser(_uid),
      shopMediaState.loadBannersForUserViaRpc(_uid),
    ];
    await Future.wait(futures);
    if (!mounted || !_isCurrentUser) return;
    final loaded = userState.getUser(_uid);
    if (loaded != null && !userState.hasError) {
      unawaited(_showOnboardingIfNeeded(_uid));
    }
  }

  String? _signedInUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  void _startLoad() {
    final next = _prime();
    setState(() {
      _ready = next;
    });
  }

  void _retry() => _startLoad();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId && _uid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ShopState>().loadForUser(_uid);
      });
    }
  }

  Future<void> _showOnboardingIfNeeded(String userId) async {
    final seen = context.read<UserState>().current.onboarded;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => OnboardingWizard()));
        setState(() {});
      });
    }
  }

  List<Shop> getVisibleShops(List<Shop> shops) {
    var filtered = shops;
    if (_searchQuery.isNotEmpty) {
      filtered = filterEntries(filtered, searchQuery: _searchQuery);
    }
    final options = _selectedSort.split('-');
    sortEntries(filtered, by: options.first, ascending: options[1] == 'asc');
    return filtered;
  }

  Future<void> _navigateToShop(String shopId, String userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(shopId: shopId, userId: userId),
      ),
    );
  }

  void _openAddShop() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const AddShopSearchPage()));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserState, u.User?>((s) => s.getUser(_uid));
    final shops = context.select<ShopState, List<Shop>>(
      (s) => s.shopsFor(_uid),
    );
    final shopsFailed = context.select<ShopState, bool>((s) => s.hasError);
    final drinkCount = context.select<ShopState, int>((s) {
      return shops.fold<int>(0, (sum, shop) {
        final id = shop.id;
        if (id == null) return sum;
        return sum + s.countsForShop(id).total;
      });
    });

    return FutureBuilder(
      future: _ready,
      builder: (context, snap) {
        final loading =
            _ready == null || snap.connectionState != ConnectionState.done;

        if (loading && (user == null || shops.isEmpty)) {
          return const HomePageSkeleton();
        }

        if (user == null || (shops.isEmpty && shopsFailed)) {
          return Scaffold(
            body: EmptyState(
              title: _isCurrentUser
                  ? 'Could not load your dex'
                  : 'Could not load this dex',
              body: 'Check your connection and try again.',
              action: BobaButton(label: 'Retry', onPressed: _retry),
            ),
          );
        }

        final visibleShops = getVisibleShops(shops);
        final bottomInset = _isCurrentUser
            ? BobaNavBar.clearance(context)
            : MediaQuery.paddingOf(context).bottom + BobaSpace.x4;

        return Scaffold(
          appBar: _isCurrentUser
              ? null
              : AppBar(title: Text('${user.firstName}\'s Bobadex')),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                if (_isCurrentUser)
                  SliverToBoxAdapter(
                    child: DexHeader(
                      title: '${user.firstName}\'s Bobadex',
                      brandCount: shops.length,
                      drinkCount: drinkCount,
                    ),
                  ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(
                    height: 108,
                    child: FilterSortBar(
                      controller: _searchController,
                      sortOptions: [
                        SortOption(
                          'favorite',
                          Icons.favorite_rounded,
                          label: 'Fav',
                        ),
                        SortOption(
                          'rating',
                          Icons.star_rounded,
                          label: 'Rating',
                        ),
                        SortOption(
                          'name',
                          Icons.sort_by_alpha_rounded,
                          label: 'Name',
                        ),
                        SortOption(
                          'createdAt',
                          Icons.schedule_rounded,
                          label: 'Added',
                        ),
                      ],
                      onSearchChanged: (query) {
                        setState(() => _searchQuery = query);
                      },
                      onSortSelected: (sortKey) {
                        setState(() => _selectedSort = sortKey);
                      },
                    ),
                  ),
                ),
                if (shops.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: _isCurrentUser
                          ? 'Your dex is empty'
                          : 'No brands yet',
                      body: _isCurrentUser
                          ? 'Add your first shop to start the collection.'
                          : 'This collector hasn\'t added any shops.',
                      action: _isCurrentUser
                          ? BobaButton(
                              label: 'Add your first shop',
                              icon: const Icon(Icons.add_rounded),
                              onPressed: _openAddShop,
                            )
                          : null,
                    ),
                  )
                else if (visibleShops.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: 'No brands found',
                      body: 'Try a different search or sort.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      BobaSpace.x2,
                      BobaSpace.x2,
                      BobaSpace.x2,
                      bottomInset,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: user.gridColumns,
                        crossAxisSpacing: BobaSpace.x2,
                        mainAxisSpacing: BobaSpace.x2,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final shop = visibleShops[index];
                        return EntryTile(
                          shop: shop,
                          columns: user.gridColumns,
                          useIcons: user.useIcons == true,
                          onTap: () async => _navigateToShop(shop.id!, user.id),
                        );
                      }, childCount: visibleShops.length),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  _FilterBarDelegate({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const columns = Constants.defaultGridColumns;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          BobaSpace.x2,
          BobaSpace.x6,
          BobaSpace.x2,
          BobaSpace.x2,
        ),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: 8,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: BobaSpace.x2,
            mainAxisSpacing: BobaSpace.x2,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return const SkeletonBox(height: 160, radius: BobaRadius.lg);
          },
        ),
      ),
    );
  }
}

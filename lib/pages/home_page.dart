import 'dart:async';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/achievements_page.dart';
import 'package:bobadex/pages/about_page.dart';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/pages/social_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/confirmation_dialog.dart';
import 'package:bobadex/widgets/onboarding_gate.dart';
import 'package:bobadex/widgets/onboarding_wizard.dart';
import 'package:bobadex/widgets/shop_grid_tile.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../helpers/sortable_entry.dart';
import '../models/shop.dart';
import '../models/user.dart' as u;
import '../widgets/filter_sort_bar.dart';
import '../state/user_state.dart';
import '../state/shop_state.dart';
import 'package:bobadex/config/constants.dart';
import 'add_shop_search_page.dart';
import '../widgets/command_icon.dart';
import 'friends_page.dart';
import 'rankings_page.dart';

class HomePage extends StatefulWidget {
  final String? userId;
  const HomePage({super.key, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final String _uid;
  late final bool _isCurrentUser;
  late Future<void> _ready = Future.value();
  String _searchQuery = '';
  String _selectedSort = 'favorite-asc';
  final _searchController = TextEditingController();

  bool get isCurrentUser {
    final currentUser = Supabase.instance.client.auth.currentUser;
    return currentUser != null && widget.userId == currentUser.id;
  }

  @override
  void initState() {
    super.initState();
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _uid = (widget.userId?.isNotEmpty == true) ? widget.userId! : authId;
    _isCurrentUser = _uid == authId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ready = _prime();
      setState(() {});
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
    if (_isCurrentUser) unawaited(_showOnboardingIfNeeded(_uid));
    await Future.wait(futures);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId && _uid.isNotEmpty) {
      // Defer the load to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ShopState>().loadForUser(_uid);
      });
    }
  }

  Future<void> _showOnboardingIfNeeded(String userId) async {
    final seen = context.read<UserState>().current.onboarded;
    if (!seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OnboardingWizard()),
        );
        setState(() {});
      });
    }
  }

  List<Shop> getVisibleShops(List<Shop> shops) {
    List<Shop> filtered = shops;

    if (_searchQuery.isNotEmpty) {
      filtered = filterEntries(filtered, searchQuery: _searchQuery);
    }

    List<String> options = _selectedSort.split('-');
    sortEntries(
      filtered,
      by: options.first,
      ascending: options[1] == 'asc',
    );

    return filtered;
  }

  Future<void> _navigateToShop(String shopId, String userId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(
          shopId: shopId,
          userId: userId,
        )
      ),
    );
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserState, u.User?>((s) => s.getUser(_uid));
    final shops = context.select<ShopState, List<Shop>>((s) => s.shopsFor(_uid));

    return FutureBuilder(
      future: _ready,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;

        if (loading && (user == null || shops.isEmpty)) {
          return const HomePageSkeleton();
        }

        if (user == null) {
          return const HomePageSkeleton();
        }

        final themeColor = Constants.getThemeColor(user.themeSlug);
        final visibleShops = getVisibleShops(shops);

        Widget shopGrid() {
          if (shops.isEmpty) {
            return const Center(child: Text("No shops added.", style: Constants.emptyListTextStyle));
          } else if (visibleShops.isEmpty) {
            return const Center(child: Text('No shops found.', style: Constants.emptyListTextStyle));
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 120),
              itemCount: visibleShops.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: user.gridColumns,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final shop = visibleShops[index];
                return ShopGridTile(
                  shop: shop,
                  columns: user.gridColumns,
                  useIcons: user.useIcons == true,
                  themeColor: themeColor,
                  onTap: () async => _navigateToShop(shop.id!, user.id),
                );
              },
            ),
          );
        }

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text('${user.firstName}\'s Bobadex'),
          ),
          drawer: isCurrentUser ? Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: themeColor.shade100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ThumbPic(path: user.profileImagePath, size: 120,),
                    ],
                  )
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage())
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.badge),
                  title: const Text('Achievements'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AchievementsPage(userId: _uid))
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About + Contact'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AboutPage())
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      message: 'Are you sure you want to sign out?',
                      title: 'Sign Out',
                      confirmText: 'Sign Out',
                      confirmColor: themeColor.shade400
                    );
                    if (confirmed) {
                      await Supabase.instance.client.auth.signOut();
                    }
                  },
                ),
              ],
            ),
          ) : null,
          body: OnboardingGate(
            isCurrentUser: isCurrentUser,
            onAddShop: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddShopSearchPage()),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FilterSortBar(
                        controller: _searchController,
                        sortOptions: [
                          SortOption('favorite', Icons.favorite),
                          SortOption('rating', Icons.star),
                          SortOption('name', Icons.sort_by_alpha),
                          SortOption('createdAt', Icons.access_time),
                        ],
                        onSearchChanged: (query) {
                          setState(() => _searchQuery = query);
                        },
                        onSortSelected: (sortKey) {
                          setState(() => _selectedSort = sortKey);
                        }
                      ),
                    ),
                    Expanded(child: shopGrid()),
                  ],
                ),
                if (isCurrentUser && MediaQuery.of(context).viewInsets.bottom == 0)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                      decoration: BoxDecoration(
                        color: themeColor.shade50,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _FriendsCommandIcon(onTap: () => _navigateToPage(FriendsPage())),
                          CommandIcon(icon: Icons.people, label: "Social", onTap: () => _navigateToPage(SocialPage())),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _navigateToPage(AddShopSearchPage()),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor == Colors.grey ? themeColor.shade400 : themeColor.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                                ),
                              ),
                            ],
                          ),
                          CommandIcon(icon: Icons.leaderboard, label: "Rankings", onTap: () => _navigateToPage(RankingsPage())),
                          CommandIcon(icon: Icons.person, label: "Profile", onTap: () => _navigateToPage(AccountViewPage(userId: user.id, user: user))),
                        ],
                      ),
                    ),
                  )
                ]
              ),
            )
          );
        }
      );
    }
}

class _FriendsCommandIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _FriendsCommandIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = context.select<FriendState, int>((s) => s.incomingRequests.length);
    return CommandIcon(
      icon: Icons.group,
      label: "Friends",
      notificationCount: count,
      onTap: onTap,
    );
  }
}

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const columns = Constants.defaultGridColumns;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: 8, // show a bit more skeletons for realism
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // top image placeholder
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  // bottom text placeholders
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 10,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

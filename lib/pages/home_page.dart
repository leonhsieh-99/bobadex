import 'dart:async';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/achievements_page.dart';
import 'package:bobadex/pages/about_page.dart';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/pages/social_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/widgets/confirmation_dialog.dart';
import 'package:bobadex/widgets/onboarding_gate.dart';
import 'package:bobadex/widgets/onboarding_wizard.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../helpers/sortable_entry.dart';
import '../models/shop.dart';
import '../widgets/filter_sort_bar.dart';
import '../state/user_state.dart';
import '../state/shop_state.dart';
import '../state/drink_state.dart';
import '../config/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final supabase = Supabase.instance.client;
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
    final futures = <Future>[
      userState.loadUser(_uid),
      shopState.loadForUser(_uid),
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
      context.read<ShopState>().loadForUser(_uid);
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

  Future<List<ShopMedia>> fetchBannersForShops(List<String> shopIds) async {
    final response = await Supabase.instance.client
      .from('shop_media')
      .select()
      .inFilter('shop_id', shopIds)
      .eq('is_banner', true);

    return (response as List)
      .map((json) => ShopMedia.fromJson(json))
      .toList();
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
    final userState = context.watch<UserState>();
    final friendState = context.watch<FriendState>();
    final brandState = context.watch<BrandState>();
    final shopMediaState = context.watch<ShopMediaState>();
    final user = context.watch<UserState>().getUser(_uid);
    final shops = context.watch<ShopState>().shopsFor(_uid);

    Widget shopGrid(List<Shop> shops, List<ShopMedia> banners) {
      final visibleShops = getVisibleShops(shops);
      final bannerByShop = { for (var b in banners) b.shopId: b };
      final themeColor = Constants.getThemeColor(user?.themeSlug ?? Constants.defaultTheme);
      if (shops.isEmpty) {
        return const Center(child: Text("No shops added.", style: Constants.emptyListTextStyle));
      } else if (visibleShops.isEmpty) {
        return const Center(child: Text('No shops found.', style:  Constants.emptyListTextStyle));
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 120),
          itemCount: visibleShops.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: user!.gridColumns,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            // view settings
            final screenWidth = MediaQuery.of(context).size.width;
            final columns = user.gridColumns;
            const spacing = 4.0;
            const baseTileWidth = 120.0;
            final itemWidth = (screenWidth - (spacing * (columns + 1))) / columns;
            final scaleFactor = itemWidth / baseTileWidth;
            final imageScale = columns == 2 ? scaleFactor * 1.2 : scaleFactor;
            final textScale = columns == 2 ? scaleFactor * 1 : scaleFactor;

            // actual data
            final shop = visibleShops[index];
            final brand = brandState.getBrand(shop.brandSlug);
            final String? url = brand?.thumbUrl;
            final bool hasValidThumb = url != null && url.isNotEmpty;
            final useIcons = user.useIcons == true;

            // banner vars
            final banner = bannerByShop[shop.id];
            final String? bannerUrl = banner?.imageUrl;
            final String? brandThumb = brand?.thumbUrl;
            final bool hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
            final bool hasBrandThumb = brandThumb != null && brandThumb.isNotEmpty;
            final String? displayUrl = hasBanner
                ? bannerUrl
                : (hasBrandThumb ? brandThumb : null);

            int uiDrinkCount(BuildContext context, String shopId) {
              final drinkState = context.watch<DrinkState>();
              final shopState = context.read<ShopState>();
              final drinks = drinkState.drinksFor(shopId);

              if (drinks.isNotEmpty) return drinks.length;
              return shopState.countsForShop(shopId).total;
            }

            return GestureDetector(
              onTap: () async => _navigateToShop(shop.id!, user.id),
              child: Card(
                elevation: 2,
                color: useIcons ? themeColor == Colors.grey ? themeColor.shade200 : themeColor.shade200 : Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: useIcons
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 4,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 85 * textScale),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: TextStyle(
                                      fontSize: 11 * textScale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.left,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'lib/assets/icons/star.svg',
                                        width: 12 * textScale,
                                        height: 12 * textScale,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        shop.rating.toStringAsFixed(1),
                                        style: TextStyle(fontSize: 12 * textScale),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ]
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        'lib/assets/icons/boba1.svg',
                                        width: 13 * textScale,
                                        height: 13 * textScale,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        uiDrinkCount(context, shop.id!).toString(),
                                        style: TextStyle(fontSize: 12 * textScale),
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 55 * imageScale,
                                height: 60 * imageScale,
                                child: hasValidThumb
                                  ? CachedNetworkImage(
                                      imageUrl: url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => CircularProgressIndicator(),
                                      errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 50 * imageScale),
                                    )
                                  : Image.asset(
                                      'lib/assets/default_icon.png',
                                      fit: BoxFit.cover,
                                    ),
                              )
                            ),
                          ),
                          if (shop.isFavorite)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SvgPicture.asset(
                              'lib/assets/icons/heart.svg',
                              width: 14 * textScale,
                              height: 14 * textScale,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Banner background
                          displayUrl != null
                            ? CachedNetworkImage(
                                imageUrl: displayUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 50 * textScale),
                              )
                            : Image.asset(
                                'lib/assets/default_icon.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                          // Gradient overlay for bottom
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 10 * textScale, horizontal: 8 * textScale),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    shop.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * textScale,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2 * textScale),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(
                                        'lib/assets/icons/star.svg',
                                        width: 12 * textScale,
                                        height: 12 * textScale,
                                        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        shop.rating.toStringAsFixed(1),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(width: 10),
                                      SvgPicture.asset(
                                        'lib/assets/icons/boba1.svg',
                                        width: 12 * textScale,
                                        height: 12 * textScale,
                                        colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        uiDrinkCount(context, shop.id!).toString(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Favorite heart
                          if (shop.isFavorite)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: SvgPicture.asset(
                              'lib/assets/icons/heart.svg',
                              width: 18 * textScale,
                              height: 18 * textScale,
                              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            );
          },
        ),
      );
    }
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

        return Scaffold(
          extendBody: true,
          backgroundColor: themeColor.shade50,
          appBar: AppBar(
            title: Text('${user.firstName}\'s Bobadex'),
            backgroundColor: themeColor.shade50,
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
                      ThumbPic(url: userState.current.thumbUrl, size: 120,),
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
                        selectedSort: _selectedSort,
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
                        onSortChanged: (sortKey) {
                          setState(() => _selectedSort = sortKey);
                        }
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final shopState = context.watch<ShopState>();

                          final shops = isCurrentUser
                              ? shopState.shopsForCurrentUser()
                              : shopState.shopsFor(_uid);

                          if (shops.isEmpty) {
                            return const HomePageSkeleton();
                          }

                          final shopIds = getVisibleShops(shops)
                              .map((s) => s.id)
                              .whereType<String>()
                              .toSet();

                          final banners = shopMediaState.all
                              .where((sm) => sm.isBanner && shopIds.contains(sm.shopId))
                              .toList();

                          return shopGrid(shops, banners);
                        },
                      ),
                    )
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
                          CommandIcon(icon: Icons.group, label: "Friends", notificationCount: friendState.incomingRequests.length, onTap: () => _navigateToPage(FriendsPage())),
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

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    const columns = Constants.defaultGridColumns;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bobadex"),
        centerTitle: true,
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
      ),
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



import 'dart:async';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/pages/splash_page.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'dart:io';
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
import 'tea_rooms_page.dart';
import 'friends_page.dart';
import 'rankings_page.dart';
import '../models/user.dart' as u;

class HomePage extends StatefulWidget {
  final u.User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String _searchQuery = '';
  String _selectedSort = 'favorite-asc';

  bool get isCurrentUser => widget.user.id == Supabase.instance.client.auth.currentUser!.id;

  Future<List<Shop>> fetchUserShops(String userId) async {
    final response = await Supabase.instance.client
        .from('shops')
        .select()
        .eq('user_id', userId);
    return (response as List).map((json) => Shop.fromJson(json)).toList();
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

  Future<void> _navigateToShop(Shop shop, user) async {
    print('Shop id: ${shop.id}');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(
          shop: shop,
          user: user,
        )
      ),
    );
  }

  void _navigateToPage(page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    final friendState = context.watch<FriendState>();
    final user = isCurrentUser ? userState.user : widget.user;

    Widget shopGrid(List<Shop> shops) {
      final visibleShops = getVisibleShops(shops);
      if (shops.isEmpty) {
        return const Center(child: Text("No shops added."));
      } else if (visibleShops.isEmpty) {
        return const Center(child: Text('No shops found.'));
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
            final screenWidth = MediaQuery.of(context).size.width;
            final columns = user.gridColumns; // e.g., 2 or 3
            const spacing = 4.0;
            const baseTileWidth = 120.0;

            final itemWidth = (screenWidth - (spacing * (columns + 1))) / columns;
            final scaleFactor = itemWidth / baseTileWidth;
            final imageScale = columns == 2 ? scaleFactor * 1.2 : scaleFactor;
            final textScale = columns == 2 ? scaleFactor * 1 : scaleFactor;

            final shop = visibleShops[index];
            return GestureDetector(
              onTap: () async => _navigateToShop(shop, user),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
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
                                    (context.watch<DrinkState>().drinksByShop[shop.id] ?? []).length.toString(),
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
                          child: shop.imagePath == null || shop.imagePath!.isEmpty
                            ? Center(child: Icon(Icons.store, size: 50 * imageScale, color: Colors.grey))
                            : (shop.imagePath != null && shop.imagePath!.startsWith('/')) 
                              ? SizedBox(
                                  width: 40 * imageScale,
                                  height: 60 * imageScale,
                                  child: Image.file(
                                    File(shop.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(child: Icon(Icons.broken_image, size: 50 * imageScale));
                                    },
                                  ),
                                )
                              : SizedBox(
                                  width: 40 * imageScale,
                                  height: 60 * imageScale,
                                  child: CachedNetworkImage(
                                    imageUrl: shop.thumbUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 50 * imageScale),
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
                ),
              ),
            );
          },
        ),
      );
    }

    if (!userState.isLoaded) {
      return const SplashPage();
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
              decoration: BoxDecoration(color: Constants.getThemeColor(user.themeSlug).shade100),
              child: Text('Bobadex Menu', style: TextStyle(color: Colors.black)),
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
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
              },
            ),
          ],
        ),
      ) : null,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: FilterSortBar(
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
              Expanded(
                child: isCurrentUser
                  ? provider.Consumer<ShopState>(
                      builder: (context, shopState, _) {
                        return shopGrid(shopState.all);
                      }
                    )
                  : FutureBuilder(
                      future: fetchUserShops(widget.user.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: SplashPage());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        return shopGrid(snapshot.data ?? []);
                      }
                    )
              ),
            ],
          ),
          if (isCurrentUser)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                decoration: BoxDecoration(
                  color: Constants.getThemeColor(user.themeSlug).shade50,
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
                    CommandIcon(icon: Icons.room, label: "Tea Rooms", onTap: () => _navigateToPage(TeaRoomsPage())),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToPage(AddShopSearchPage()),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Constants.getThemeColor(user.themeSlug).shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),

                    CommandIcon(icon: Icons.leaderboard, label: "Rankings", onTap: () => _navigateToPage(RankingsPage())),
                    CommandIcon(icon: Icons.person, label: "Profile", onTap: () => _navigateToPage(AccountViewPage(user: user))),
                  ],
                ),
              ),
            )
          ]
        ),
      );
    }
}
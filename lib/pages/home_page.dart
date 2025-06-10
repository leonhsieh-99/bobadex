import 'dart:async';
import 'package:bobadex/pages/setting_pages/settings_account_page.dart';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/brand_state.dart';
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
import 'tea_room_page.dart';
import 'friends_page.dart';
import 'brand_rankings_page.dart';

class HomePage extends StatefulWidget {
  final Session session;
  const HomePage({super.key, required this.session});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  String _searchQuery = '';
  String _selectedSort = 'favorite-asc';

  List<Shop> get _shops {
    return context.watch<ShopState>().all;
  }

  List<Shop> get visibleShops {
    List<Shop> filtered = [..._shops];

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

  Future<void> _navigateToShop(Shop shop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(
          shop: shop,
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
    final user = context.watch<UserState>().user;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text('${user.firstName}\'s Bobadex'),
      ),
      drawer: Drawer(
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
                context.read<UserState>().reset();
                context.read<ShopState>().reset();
                context.read<DrinkState>().reset();
                context.read<BrandState>().reset();
              },
            ),
          ],
        ),
      ),
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
                child: _shops.isEmpty
                  ? const Center(child: Text('No shops yet. Tap + to add!'))
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 120),
                        itemCount: visibleShops.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          final shop = visibleShops[index];
                          return GestureDetector(
                            onTap: () async => _navigateToShop(shop),
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
                                        constraints: const BoxConstraints(maxWidth: 85),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shop.name,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.left,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            Row(
                                              children: [
                                                SvgPicture.asset(
                                                  'lib/assets/icons/star.svg',
                                                  width: 12,
                                                  height: 12,
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  shop.rating.toStringAsFixed(1),
                                                  style: const TextStyle(fontSize: 12),
                                                  textAlign: TextAlign.left,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ]
                                            )
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
                                          ? const Center(child: Icon(Icons.store, size: 40, color: Colors.grey))
                                          : (shop.imagePath != null && shop.imagePath!.startsWith('/')) 
                                            ? SizedBox(
                                                width: 40,
                                                height: 60,
                                                child: Image.file(
                                                  File(shop.imagePath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Center(child: Icon(Icons.broken_image));
                                                  },
                                                ),
                                              )
                                            : SizedBox(
                                                width: 40,
                                                height: 60,
                                                child: CachedNetworkImage(
                                                  imageUrl: shop.thumbUrl,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => CircularProgressIndicator(),
                                                  errorWidget: (context, url, error) => Icon(Icons.broken_image),
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
                                        width: 14,
                                        height: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                  CommandIcon(icon: Icons.group, label: "Friends", onTap: () => _navigateToPage(FriendsPage())),
                  CommandIcon(icon: Icons.room, label: "Tea Room", onTap: () => _navigateToPage(TeaRoomPage())),

                  // 🌟 Highlighted Add Shop Button
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
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),

                  CommandIcon(icon: Icons.leaderboard, label: "Rankings", onTap: () => _navigateToPage(BrandRankingsPage())),
                  CommandIcon(icon: Icons.person, label: "Profile", onTap: () => _navigateToPage(SettingsAccountPage())),
                ],
              ),
            ),
          )
        ]
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     await Navigator.of(context).push<String>(
      //       MaterialPageRoute(
      //         builder: (_) => AddShopSearchPage(),
      //       ),
      //     );
      //   },
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}

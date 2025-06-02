import 'dart:async';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
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
import '../widgets/add_edit_shop_dialog.dart';
import '../config/constants.dart';
import 'auth_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _addShop(Shop shop) async {
    final userId = widget.session.user.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String tempId = 'temp-$timestamp'; 
    final shopState = context.read<ShopState>();

    // Create a temporary shop with local image for immediate UI feedback
    final tempShop = Shop(
      id: tempId,
      name: shop.name,
      rating: shop.rating,
      imagePath: shop.imagePath,// Use local file path initially
      isFavorite: shop.isFavorite,
    );

    // Optimistically update UI
    shopState.add(tempShop);

    // then insert shop into db
    try {
      final insertResponse = await supabase.from('shops')
        .insert({
          'user_id': userId,
          'name': shop.name,
          'image_path': shop.imagePath,
          'rating': shop.rating,
          'is_favorite': shop.isFavorite,
        }).select();

      final insertedShop = Shop.fromJson(insertResponse.first);

      shopState.replace(tempId, insertedShop);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success'))
      );
    } catch (e) {
      print('❌ Insert failed: $e');
      shopState.remove(tempId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add shop: ${e.toString()}'))
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('${userState.displayName}\'s Bobadex'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Constants.getThemeColor(userState.themeSlug ?? Constants.defaultTheme).shade100),
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
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GridView.builder(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (_) => AddOrEditShopDialog(
              onSubmit: (shop) async {
                _addShop(Shop(
                  name: shop.name,
                  rating: shop.rating,
                  imagePath: shop.imagePath,
                  notes: shop.notes,
                ));
              }
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'dart:async';
import 'package:bobadex/pages/settings_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:flutter/material.dart';
import 'widgets/add_edit_shop_dialog.dart';
import 'pages/auth_page.dart';
import 'models/shop.dart';
import 'pages/splash_page.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'helpers/sortable_entry.dart';
import 'package:collection/collection.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'models/drink.dart';
import 'models/drink_cache.dart';
import 'widgets/filter_sort_bar.dart';
import 'models/user_cache.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, 
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  runApp(BobadexApp());
}

class BobadexApp extends StatefulWidget {
  const BobadexApp({super.key});

  @override
  State<BobadexApp> createState() => _BobadexAppState();
}

class _BobadexAppState extends State<BobadexApp> {
  bool _isReady = false;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      // Wait for Supabase to restore session
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      if (currentSession != null) {
        setState(() {
          _session = currentSession;
          _isReady = true;
        });
      }

      // Listen for auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        print('Auth state changed: ${data.event}');
        print('New session: ${data.session}');
        setState(() {
          _session = data.session;
          _isReady = true;
        });
      });

      // Double check session after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      final refreshedSession = Supabase.instance.client.auth.currentSession;

      // initialize drink cache
      try {
        final response = await Supabase.instance.client.from('drinks').select();
        final allDrinks = (response as List).map((json) => Drink.fromJson(json)).toList();
        DrinkCache.set(allDrinks);
      } catch (e) {
        print('Error loading drinks: $e');
      }

      // load user info
      try {
        UserCache.loadFromSupbase();
      } catch (e) {
        print('Error loading user settings: $e');
      }
      
      if (!_isReady && refreshedSession != null) {
        setState(() {
          _session = refreshedSession;
          _isReady = true;
        });
      } else if (!_isReady) {
        setState(() {
          _isReady = true;
        });
      }
    } catch (e) {
      print('📦 Error initializing session: $e');
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bobadex',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: UserCache.themMaterial.shade50,
          foregroundColor: Colors.black,
        ),
        scaffoldBackgroundColor: UserCache.themMaterial.shade50,
        cardTheme: CardThemeData(
          color: UserCache.themMaterial.shade100,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: UserCache.themMaterial.shade50,
        ),
      ),
      home: !_isReady
        ? const SplashPage()
        : _session == null
          ? const AuthPage()
          : HomePage(session: _session!),
    );
  }
}

class HomePage extends StatefulWidget {
  final Session session;
  const HomePage({super.key, required this.session});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _selectedSort = 'favorite-asc';
  List<Shop> _shops = [];

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
  
  Future<void> _loadShops({bool isBackgroundRefresh = false}) async {
    final userId = widget.session.user.id;

    if (!isBackgroundRefresh) {
      setState(() => _isInitialLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    try {
      final response = await supabase
        .from('shops')
        .select()
        .eq('user_id', userId)
        .order('rating');
      final data = response as List;
      final updatedShops = await Future.wait(data.map((json) async {
        final newPath = json['image_path'];
        final existing = _shops.firstWhereOrNull((s) => s.id == json['id']);

        if (existing != null &&
            existing.imagePath == newPath &&
            existing.imageUrl.isNotEmpty) {
          return existing;
        } else {
          return Shop.fromJson(json);
        }
      }));

      setState(() => _shops = updatedShops);
    } catch(e) {
      print('Error loading shops: $e');
    } finally {
      setState(() {
        if (!isBackgroundRefresh) {
          _isInitialLoading = false;
        } else {
          _isRefreshing = false;
        }
      });
    }
  }

  void _addShop(Shop shop) async {
    final userId = widget.session.user.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String tempId = 'temp-$timestamp'; 

    // Create a temporary shop with local image for immediate UI feedback
    final tempShop = Shop(
      id: tempId,
      name: shop.name,
      rating: shop.rating,
      imagePath: shop.imagePath,// Use local file path initially
      isFavorite: shop.isFavorite,
      drinks: shop.drinks,
    );

    // Optimistically update UI
    setState(() {
      _shops = [..._shops, tempShop];
    });

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

      setState(() {
        _shops = _shops.map((s) => s.id == tempId ? insertedShop : s).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success'))
      );
      _loadShops(isBackgroundRefresh: true);
    } catch (e) {
      print('❌ Insert failed: $e');
      setState(() => _shops = _shops.where((s) => s.id != tempId).toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add shop: ${e.toString()}'))
      );
    }
  }

  Future<void> _navigateToShop(Shop shop) async {
    final completer = Completer<Shop?>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailPage(
          shop: shop,
          resultCompleter: completer,
        )
      ),
    );

    final result = await completer.future;

    // deleted shop
    if (result == null) {
      setState(() {
        _shops.removeWhere((s) => s.id == shop.id);
      });
      return;
    }

    // edited shop
    if (result.id == shop.id) {
      setState(() {
        _shops = _shops.map((s) => s.id == result.id ? result : s).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${UserCache.displayName}\'s Bobadex'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color.fromARGB(255, 45, 42, 42)),
              child: Text('Bobadex Menu', style: TextStyle(color: Colors.grey)),
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
      body: _isInitialLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
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
                                            Text(
                                              '⭐ ${shop.rating.toStringAsFixed(1)}',
                                              style: const TextStyle(fontSize: 11),
                                              textAlign: TextAlign.left,
                                              overflow: TextOverflow.ellipsis,
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
                                    const Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Icon(Icons.favorite, color: Colors.deepPurpleAccent, size: 20),
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
              if (_isRefreshing)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
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

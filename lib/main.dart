import 'package:flutter/material.dart';
import 'add_shop_page.dart';
import 'auth_page.dart';
import 'models/shop.dart';
import 'splash_page.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      theme: ThemeData(primarySwatch: Colors.brown),
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
  List<Shop> _shops = [];

  Future<void> _loadShops({bool isBackgroundRefresh = false}) async {
    final userId = widget.session.user.id;

    if (!isBackgroundRefresh) {
      setState(() => _isInitialLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }

    print('loading shops...');
    try {
      final response = await supabase
        .from('shops')
        .select()
        .eq('user_id', userId)
        .order('created_at');
      try {
        final data = response as List;
        final shops = await Future.wait(data.map((json) => Shop.fromJsonWithSignedUrl(json)));
        setState(() {
          _shops = shops;
        });
        print('shops loaded');
      } catch (e) {
        print ('failed to parse data $e');
      }
    } on Exception catch(e) {
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
    final String filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String imagePath = 'public/$filename';

    // Create a temporary shop with local image for immediate UI feedback
    final tempShop = Shop(
      name: shop.name,
      rating: shop.rating,
      imageUrl: shop.imageUrl, // Use local file path initially
      isFavorite: shop.isFavorite,
    );

    // Optimistically update UI
    setState(() {
      _shops = [..._shops, tempShop];
    });

    try {
      // Start both operations in parallel
      final bytes = await File(shop.imageUrl).readAsBytes();
      
      // Upload image and insert shop record concurrently
      final uploadFuture = supabase.storage
        .from('shop-images')
        .uploadBinary(
          imagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

      final insertFuture = supabase.from('shops')
        .insert({
          'user_id': userId,
          'name': shop.name,
          'image_url': imagePath,
          'rating': shop.rating,
          'is_favorite': shop.isFavorite,
        })
        .select().then((res) => res);

      final results = await Future.wait([uploadFuture, insertFuture]);


      // Get the shop data from the insert response
      final response = results[1] as List;
      final newShop = await Shop.fromJsonWithSignedUrl(response.first);
      
      // Update UI with the real shop data
      setState(() {
        _shops = _shops.map((s) => 
          s == tempShop ? newShop : s
        ).toList();
      });

      // Silently refresh in background
      _loadShops(isBackgroundRefresh: true).then((_) {
        print('📦 Background refresh completed');
      }).catchError((e) {
        print('❌ Background refresh failed: $e');
      });

    } on Exception catch(e) {
      print('❌ Insert failed: $e');
      // Remove the temporary shop on error
      setState(() {
        _shops = _shops.where((s) => s != tempShop).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add shop: ${e.toString()}'))
      );
    }
  }

  void _navigateToAddShop() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddShopPage()),
    );

    if (result != null && result is Shop) {
      _addShop(result);
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
      appBar: AppBar(title: const Text('Your Bobadex')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.brown),
              child: Text('Bobadex Menu', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: settings page
                Navigator.pop(context);
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
        : Stack(
            children: [
              _shops.isEmpty
                ? const Center(child: Text('No shops yet. Tap + to add!'))
                : GridView.builder(
                    itemCount: _shops.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<String>(
                                    future: shop.getImageUrl(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      return Image.network(
                                        snapshot.data ?? shop.imageUrl,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('❌ Image load error: $error');
                                          return const Center(
                                            child: Icon(Icons.error_outline),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${shop.name} - ⭐ ${shop.rating.toStringAsFixed(1)}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddShop,
        child: const Icon(Icons.add),
      ),
    );
  }
}

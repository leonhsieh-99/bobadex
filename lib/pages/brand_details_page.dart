import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/shop_gallery_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bobadex/widgets/add_edit_shop_dialog.dart';

class BrandDetailsPage extends StatefulWidget {
  final Brand brand;

  const BrandDetailsPage({super.key, required this.brand});

  @override
  State<BrandDetailsPage> createState() => _BrandDetailsPageState();
}

class _BrandDetailsPageState extends State<BrandDetailsPage> {
  late Future<BrandStats> _statsFuture;
  late Future<List<ShopMedia>> _globalGalleryFuture;

  @override
  void initState() {
    fetchStats();
    super.initState();
    _statsFuture = fetchStats();
    _globalGalleryFuture = fetchGallery();
  }

  Future<BrandStats> fetchStats() async {
    try {
      final response = await Supabase.instance.client
        .rpc('get_brand_stats', params: {'brand_slug': widget.brand.slug});

      final data = (response as List).firstOrNull;
      final b = widget.brand;
      return BrandStats(
        slug: b.slug,
        display: b.display,
        iconPath: b.iconPath,
        avgRating: data['avg_rating'],
        shopCount: data['shop_count']
      );
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return BrandStats.fromJson({});
    }
  }

  Future<List<ShopMedia>> fetchGallery() async {
    try {
      final response = await Supabase.instance.client
        .rpc('get_brand_gallery', params: {'brand_slug': widget.brand.slug});

      return (response as List)
        .map((item) => ShopMedia.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetching gallery: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.watch<ShopState>();
    final achievementState = context.read<AchievementsState>();
    final userState = context.watch<UserState>();
    final hasVisit = shopState.all.map((s) => s.brandSlug).contains(widget.brand.slug);
    final userShop = shopState.getShopByBrand(widget.brand.slug);
    final themeColor = Constants.getThemeColor(userState.user.themeSlug);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Brand avatar
                  Center(
                    child: ClipOval(
                      child: widget.brand.iconPath != null && widget.brand.iconPath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.brand.thumbUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            'lib/assets/default_icon.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                  // Add button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: themeColor.shade200,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 3,
                        minimumSize: Size(0,0)
                      ),
                      child: Text(
                        hasVisit ? "Edit Visit" : "Add Visit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => AddOrEditShopDialog(
                            shop: hasVisit ? userShop : null,
                            onSubmit: (submittedShop) async {
                              try {
                                if (hasVisit) {
                                  final persistedShop = await shopState.update(submittedShop);
                                  return persistedShop;
                                } else {
                                  final persistedShop = await shopState.add(submittedShop);
                                  await achievementState.checkAndUnlockShopAchievement(shopState);
                                  await achievementState.checkAndUnlockBrandAchievement(shopState);
                                  return persistedShop;
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to update shop.')),
                                  );
                                }
                                rethrow;
                              }
                            },
                            brand: widget.brand,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.brand.display,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildGlobalRatings(widget.brand, _statsFuture),
          const SizedBox(height: 24),
          _buildGlobalGallery(widget.brand, _globalGalleryFuture),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

Widget _buildGlobalRatings(Brand brand, Future<BrandStats> statsFuture) {
  return FutureBuilder(
    future: statsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      if (snapshot.hasError) {
        return Text('Failed to load stats', style: TextStyle(color: Colors.red));
      }
      final stats = snapshot.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Text('${stats.avgRating.toStringAsFixed(1)} (${stats.shopCount} ratings)',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      );
    }
  );
}

Widget _buildGlobalGallery(Brand brand, Future<List<ShopMedia>> galleryFuture) {
  return FutureBuilder<List<ShopMedia>>(
    future: galleryFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: LinearProgressIndicator(minHeight: 2),
        );
      }
      if (snapshot.hasError) {
        return Text('Failed to load gallery', style: TextStyle(color: Colors.red));
      }
      final medias = snapshot.data ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: medias.isEmpty
              ? const Center(child: Text('No community photos yet'))
              : HorizontalPhotoPreview(shopMediaList: medias, onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) =>
                  ShopGalleryPage(
                    shopMediaList: medias,
                    isCurrentUser: false
                  )
                )
              ))
          ),
        ],
      );
    },
  );
}

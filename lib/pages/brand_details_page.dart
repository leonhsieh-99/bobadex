import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/show_snackbar.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/shop_gallery_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/brand_feed_view.dart';
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

  Future<List<ShopMedia>> fetchGallery({int offset = 0, limit = 20}) async {
    try {
      final response = await Supabase.instance.client
        .rpc('get_brand_gallery', params: {
          'brand_slug': widget.brand.slug,
          'offset_count': offset,
          'limit_count': limit,
        });

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

    Widget buildGlobalGallery(Brand brand, Future<List<ShopMedia>> galleryFuture) {
      return FutureBuilder<List<ShopMedia>>(
        future: galleryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                HorizontalPreviewSkeleton(count: 3, height: 200, width: 150),
              ],
            );
          }
          if (snapshot.hasError) {
            return Text('Failed to load gallery', style: TextStyle(color: Colors.red));
          }
          final medias = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Spacer(),
                  if(medias.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(    
                            builder: (_) => ShopGalleryPage(
                              shopMediaList: medias,
                              isCurrentUser: false,
                              onFetchMore: (offset, limit) => fetchGallery(offset: offset, limit: limit),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 200,
                child: medias.isEmpty
                  ? const Center(child: Text('No community photos yet', style: Constants.emptyListTextStyle))
                  : HorizontalPhotoPreview(maxPreview: 3, height: 200, width: 150, shopMediaList: medias, onViewAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) =>
                      ShopGalleryPage(
                        shopMediaList: medias,
                        isCurrentUser: false,
                        onFetchMore: (offset, limit) => fetchGallery(offset: offset, limit: limit),
                      )
                    )
                  ))
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              _buildBrandBanner(
                context,
                widget.brand,
                _globalGalleryFuture,
                buildBannerContent(context, widget.brand, _statsFuture),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: themeColor == Colors.grey ? themeColor.shade500 : themeColor.shade200,
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
                            debugPrint('error: $e');
                            if (context.mounted) { showAppSnackBar(context, 'Failed to update shop.', type: SnackType.error); }
                            rethrow;
                          }
                        },
                        brand: widget.brand,
                      ),
                    );
                  },
                ),
              ),
            ]
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                buildGlobalGallery(widget.brand, _globalGalleryFuture),
                const SizedBox(height: 24),
                Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                BrandFeedView(brandSlug: widget.brand.slug),
              ],
            ),
          )
        ]
      )
    );
  }
}

Widget _buildGlobalRatings(Brand brand, Future<BrandStats> statsFuture) {
  return FutureBuilder(
    future: statsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          width: 100,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }
      if (snapshot.hasError) {
        return Text('Failed to load stats', style: TextStyle(color: Colors.red));
      }
      final stats = snapshot.data!;
      return Row(
        children: [
          const Icon(Icons.star, color: Colors.orangeAccent),
          const SizedBox(width: 2),
          Text(
            '${stats.avgRating.toStringAsFixed(1)} (${stats.shopCount} ratings)',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            )
          ),
        ],
      );
    }
  );
}

Widget _buildBrandBanner(
  BuildContext context,
  Brand brand,
  Future<List<ShopMedia>> galleryFuture,
  Widget childContent,
) {
  return FutureBuilder(
    future: galleryFuture,
    builder: (context, snapshot) {
      String? bgUrl;
      if (snapshot.hasData && (snapshot.data?.isNotEmpty ?? false)) {
        final images = snapshot.data!;
        bgUrl = (images..shuffle()).first.imageUrl;
      }

      return Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // banner
            if (bgUrl != null)
              CachedNetworkImage(
                imageUrl: bgUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.35),
                colorBlendMode: BlendMode.darken,
              ),
            // gradient
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: childContent,
              ),
            )
          ],
        ),
      );
    }
  );
}

Widget buildBannerContent(BuildContext context, Brand brand, Future<BrandStats> statsFuture) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end, // bottom align children
      children: [
        ClipOval(
          child: brand.iconPath != null && brand.iconPath!.isNotEmpty
            ? CachedNetworkImage(
              imageUrl: brand.thumbUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            )
            : Image.asset(
              'lib/assets/default_icon.png',
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                brand.display,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 0),
              _buildGlobalRatings(brand, statsFuture),
            ],
          ),
        ),
      ],
    ),
  );
}
import 'dart:convert';

import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/models/brand_profile.dart';
import 'package:bobadex/models/brand_stats.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/notification_bus.dart';
import 'package:bobadex/pages/shop_gallery_page.dart';
import 'package:bobadex/state/achievements_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/widgets/brand_about_section.dart';
import 'package:bobadex/widgets/icon_pic.dart';
import 'package:bobadex/widgets/social_widgets/brand_feed_view.dart';
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
  late Future<BrandProfile> _profileFuture;
  int? _photoCount;
  int? _feedCount;

  @override
  void initState() {
    super.initState();
    _statsFuture = fetchStats();
    _globalGalleryFuture = fetchGallery();
    _profileFuture = fetchProfile();
  }

  Future<String?> reportBrandClosed() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'report-brand-closed',
        body: {
          'slug': widget.brand.slug,
          'name': widget.brand.display,
          'id': Supabase.instance.client.auth.currentUser!.id
        },
      );

      final status = response.status;
      final raw = response.data;

      final Map<String, dynamic>? data = raw is String
        ? json.decode(raw) as Map<String, dynamic>
        : (raw is Map ? (raw).cast<String, dynamic>() : null);

      if ((status == 200 || status == 201) && data != null) {
        return data['result'];
      }
      return 'Unknown error occurred. ($status)';
    } on FunctionException catch (e) {
      debugPrint('report-brand failed: status=${e.status}, details=${e.details}, reason=${e.reasonPhrase}');

      Map<String, dynamic>? details;
      if (e.details is Map<String, dynamic>) {
        details = e.details as Map<String, dynamic>;
      } else if (e.details is String) {
        try { details = json.decode(e.details as String) as Map<String, dynamic>; } catch (_) {}
      }

      final message = details?['message'] as String? ?? e.reasonPhrase ?? 'Request failed';
      return message;
    } catch (e) {
      debugPrint('report-brand unexpected error: $e');
      return 'Failed to report brand';
    }
  }


  Future<BrandProfile> fetchProfile() async {
    final client = Supabase.instance.client;
    Map<String, dynamic>? row;
    String? website = widget.brand.website;

    try {
      row = await client
          .from('brand_profiles')
          .select('public_summary, profile_facts')
          .eq('brand_slug', widget.brand.slug)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching brand profile: $e');
    }

    if (website == null || website.isEmpty) {
      try {
        final brandRow = await client
            .from('brands')
            .select('website')
            .eq('slug', widget.brand.slug)
            .maybeSingle();
        website = brandRow?['website'] as String?;
      } catch (e) {
        debugPrint('Brand website column unavailable: $e');
      }
    }

    return BrandProfile.fromJson(row, websiteFallback: website);
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
        avgRating: (data['avg_rating'] as num).toDouble(),
        shopCount: data['shop_count']
      );
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return BrandStats.fromJson({});
    }
  }

  Future<List<ShopMedia>> fetchGallery({int offset = 0, limit = Constants.defaultGalleryLimit}) async {
    try {
      final response = await Supabase.instance.client
        .rpc('get_brand_gallery', params: {
          'brand_slug': widget.brand.slug,
          'offset_count': offset,
          'limit_count': limit,
        });

      final medias = (response as List)
        .map((item) => ShopMedia.fromJson(item)).toList();
      if (offset == 0 && mounted && _photoCount != medias.length) {
        setState(() => _photoCount = medias.length);
      }
      return medias;
    } catch (e) {
      debugPrint('Error fetching gallery: $e');
      if (offset == 0 && mounted && _photoCount != 0) {
        setState(() => _photoCount = 0);
      }
      return [];
    }
  }

  void viewAllPhotos(List<ShopMedia> medias) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) =>
        ShopGalleryPage(
          shopMediaList: medias,
          isCurrentUser: false,
          onFetchMore: (offset, limit) => fetchGallery(offset: offset, limit: limit),
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopState = context.read<ShopState>();
    final achievementState = context.read<AchievementsState>();
    final currentId = context.select<UserState, String>((s) => s.current.id);
    final themeSlug = context.select<UserState, String>((s) => s.current.themeSlug);
    final userShop = context.select<ShopState, Shop?>(
      (s) => s.getShopByBrand(currentId, widget.brand.slug),
    );
    final hasVisit = userShop != null;
    final themeColor = Constants.getThemeColor(themeSlug);
    final analytics = context.read<AnalyticsService>();

    Widget buildGlobalGallery(Brand brand, Future<List<ShopMedia>> galleryFuture) {
      return FutureBuilder<List<ShopMedia>>(
        future: galleryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return Text('Failed to load gallery', style: TextStyle(color: Colors.red));
          }
          final medias = snapshot.data ?? [];
          if (medias.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Spacer(),
                  if(medias.isNotEmpty)
                    TextButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                        foregroundColor: WidgetStatePropertyAll(Colors.black),
                      ),
                      onPressed: () {
                        viewAllPhotos(medias);
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
                child: HorizontalPhotoPreview(maxPreview: 3, height: 200, width: 150, shopMediaList: medias, onViewAll: () => viewAllPhotos(medias))
              ),
            ],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildBrandBanner(
                    context,
                    widget.brand,
                    _globalGalleryFuture,
                    buildBannerContent(context, widget.brand, _statsFuture),
                    (medias) => viewAllPhotos(medias),
                  ),
                  // back button
                  Positioned(
                    top: 0,
                    left: 4,
                    child: SafeArea(
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  // add visit button
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: themeColor == Colors.grey ? themeColor.shade500 : themeColor,
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
                                  notify('Shop updated', SnackType.success);
                                  return persistedShop;
                                } else {
                                  final persistedShop = await shopState.add(submittedShop);
                                  analytics.shopAdded(rating: persistedShop.rating, brandSlug: persistedShop.brandSlug);
                                  await achievementState.checkAndUnlockShopAchievement(shopState);
                                  await achievementState.checkAndUnlockBrandAchievement(shopState);
                                  return persistedShop;
                                }
                              } catch (e, st) {
                                debugPrint('error in onSubmit: $e');
                                debugPrintStack(stackTrace: st);
                                notify('Failed to update shop.', SnackType.error);
                                return Future.error(e);
                              }
                            },
                            brand: widget.brand,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 25,
                    right: 10,
                    child: PopupMenuButton(
                      icon: Icon(Icons.more_horiz, color: Colors.white, size: 24),
                      onSelected: (value) async {
                        switch(value) {
                          case 'report':
                            final result = await reportBrandClosed();
                            print(result);
                            if (result != null && (result == 'incremented' || result == 'created')) {
                              notify('Report pending review', SnackType.info);
                            } else if (result != null ) {
                              debugPrint(result);
                              notify(result, SnackType.error);
                            }
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Text('Report closed')
                        )
                      ]
                    ),
                  )
                ]
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<BrandProfile>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const BrandAboutSkeleton();
                        }
                        final profile = snapshot.data;
                        if (profile == null || !profile.hasContent) {
                          return const SizedBox.shrink();
                        }
                        return BrandAboutSection(
                          profile: profile,
                          themeColor: themeColor,
                        );
                      },
                    ),
                    buildGlobalGallery(widget.brand, _globalGalleryFuture),
                    if (_feedCount != null && _feedCount! > 0) ...[
                      const SizedBox(height: 24),
                      const Text("Recent Activity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                    if (_photoCount == 0 && _feedCount == 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Be the first to log a visit or add a photo.',
                          style: Constants.emptyListTextStyle,
                        ),
                      ),
                  ],
                ),
              ),
              BrandFeedView(
                brandSlug: widget.brand.slug,
                hideWhenEmpty: true,
                onItemCount: (count) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _feedCount == count) return;
                    setState(() => _feedCount = count);
                  });
                },
              ),
            ]
          ),
        ),
      ),
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
            stats.avgRating == 0
              ? 'Unrated'
              : '${stats.avgRating.toStringAsFixed(1)} (${stats.shopCount} ratings)',
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
  ValueChanged<List<ShopMedia>> onTapWithMedias,
) {
  return FutureBuilder<List<ShopMedia>>(
    future: galleryFuture,
    builder: (context, snapshot) {
      final medias = snapshot.data ?? [];
      String? bgUrl;
      if (medias.isNotEmpty) {
        final images = List<ShopMedia>.of(medias);
        images.shuffle();
        bgUrl = images.first.imageUrl;
      }

      return InkWell(
        onTap: medias.isNotEmpty ? () => onTapWithMedias(medias) : null, // ⬅️ wire here
        child: Container(
          height: 250,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: const BoxDecoration(color: Colors.grey),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bgUrl != null)
                CachedNetworkImage(
                  imageUrl: bgUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.35),
                  colorBlendMode: BlendMode.darken,
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: childContent,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget buildBannerContent(BuildContext context, Brand brand, Future<BrandStats> statsFuture) {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end, // bottom align children
      children: [
        IconPic(path: brand.iconPath),
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
import 'dart:convert';

import 'package:bobadex/analytics_service.dart';
import 'package:bobadex/config/constants.dart';
import 'package:bobadex/helpers/save_shop_visit.dart';
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
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:bobadex/widgets/social_widgets/brand_feed_view.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bobadex/widgets/add_edit_shop_dialog.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';

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
          'id': Supabase.instance.client.auth.currentUser!.id,
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
      debugPrint(
        'report-brand failed: status=${e.status}, details=${e.details}, reason=${e.reasonPhrase}',
      );

      Map<String, dynamic>? details;
      if (e.details is Map<String, dynamic>) {
        details = e.details as Map<String, dynamic>;
      } else if (e.details is String) {
        try {
          details = json.decode(e.details as String) as Map<String, dynamic>;
        } catch (_) {}
      }

      final message =
          details?['message'] as String? ?? e.reasonPhrase ?? 'Request failed';
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
      final response = await Supabase.instance.client.rpc(
        'get_brand_stats',
        params: {'brand_slug': widget.brand.slug},
      );

      final data = (response as List).firstOrNull;
      final b = widget.brand;
      return BrandStats(
        slug: b.slug,
        display: b.display,
        iconPath: b.iconPath,
        avgRating: (data['avg_rating'] as num).toDouble(),
        shopCount: data['shop_count'],
      );
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return BrandStats.fromJson({});
    }
  }

  Future<List<ShopMedia>> fetchGallery({
    int offset = 0,
    limit = Constants.defaultGalleryLimit,
  }) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_brand_gallery',
        params: {
          'brand_slug': widget.brand.slug,
          'offset_count': offset,
          'limit_count': limit,
        },
      );

      final medias = (response as List)
          .map((item) => ShopMedia.fromJson(item))
          .toList();
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
      MaterialPageRoute(
        builder: (_) => ShopGalleryPage(
          shopMediaList: medias,
          isCurrentUser: false,
          onFetchMore: (offset, limit) =>
              fetchGallery(offset: offset, limit: limit),
        ),
      ),
    );
  }

  Future<void> _openVisit() async {
    final shopState = context.read<ShopState>();
    final achievementState = context.read<AchievementsState>();
    final analytics = context.read<AnalyticsService>();
    final currentId = context.read<UserState>().current.id;
    final userShop = shopState.getShopByBrand(currentId, widget.brand.slug);
    final hasVisit = userShop != null;

    await AddOrEditShopDialog.show(
      context,
      shop: hasVisit ? userShop : null,
      brand: widget.brand,
      onSubmit: (submittedShop) async {
        try {
          final persistedShop = await saveShopVisit(
            shop: submittedShop,
            isNew: !hasVisit,
            shopState: shopState,
            achievements: achievementState,
            analytics: analytics,
          );
          return persistedShop;
        } catch (e, st) {
          debugPrint('error in onSubmit: $e');
          debugPrintStack(stackTrace: st);
          notify('Failed to update shop.', SnackType.error);
          return Future.error(e);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentId = context.select<UserState, String>((s) => s.current.id);
    final userShop = context.select<ShopState, Shop?>(
      (s) => s.getShopByBrand(currentId, widget.brand.slug),
    );
    final hasVisit = userShop != null;

    Widget buildGlobalGallery(
      Brand brand,
      Future<List<ShopMedia>> galleryFuture,
    ) {
      return FutureBuilder<List<ShopMedia>>(
        future: galleryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError) {
            return Text(
              'Failed to load gallery',
              style: TextStyle(color: context.boba.danger),
            );
          }
          final medias = snapshot.data ?? [];
          if (medias.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (medias.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: context.boba.ink,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => viewAllPhotos(medias),
                        child: const Text(
                          'View all',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 140,
                  child: HorizontalPhotoPreview(
                    maxPreview: 4,
                    height: 140,
                    width: 110,
                    shopMediaList: medias,
                    onViewAll: () => viewAllPhotos(medias),
                  ),
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
                    buildBannerContent(
                      context,
                      widget.brand,
                      _statsFuture,
                      userShop,
                    ),
                    (medias) => viewAllPhotos(medias),
                  ),
                  // back button
                  Positioned(
                    top: 0,
                    left: 4,
                    child: SafeArea(
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: context.boba.onImage,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: context.boba.accent,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        elevation: 3,
                        minimumSize: Size.zero,
                      ),
                      onPressed: _openVisit,
                      child: Text(
                        hasVisit ? 'Edit Visit' : 'Add Visit',
                        style: TextStyle(
                          color: context.boba.onAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 4,
                    child: SafeArea(
                      child: PopupMenuButton(
                        icon: Icon(
                          Icons.more_horiz,
                          color: context.boba.onImage,
                          size: 24,
                        ),
                        onSelected: (value) async {
                          switch (value) {
                            case 'report':
                              final result = await reportBrandClosed();
                              print(result);
                              if (result != null &&
                                  (result == 'incremented' ||
                                      result == 'created')) {
                                notify('Report pending review', SnackType.info);
                              } else if (result != null) {
                                debugPrint(result);
                                notify(result, SnackType.error);
                              }
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'report',
                            child: Text('Report closed'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userShop != null) ...[
                      _YourVisitCard(shop: userShop, onEdit: _openVisit),
                      const SizedBox(height: BobaSpace.x3),
                    ],
                    FutureBuilder<BrandProfile>(
                      future: _profileFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const BrandAboutSkeleton();
                        }
                        final profile = snapshot.data;
                        if (profile == null || !profile.hasContent) {
                          return const SizedBox.shrink();
                        }
                        return BrandAboutSection(profile: profile);
                      },
                    ),
                    buildGlobalGallery(widget.brand, _globalGalleryFuture),
                    if (_photoCount == 0 && _feedCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Be the first to log a visit or add a photo.',
                          style: context.bobaText.empty,
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
            ],
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
            color: context.boba.outline,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }
      if (snapshot.hasError) {
        return Text(
          'Failed to load stats',
          style: TextStyle(color: context.boba.danger),
        );
      }
      final stats = snapshot.data!;
      return Row(
        children: [
          Icon(Icons.star_rounded, color: context.boba.star),
          const SizedBox(width: 2),
          Text(
            stats.avgRating == 0
                ? 'Unrated'
                : '${stats.avgRating.toStringAsFixed(1)} (${stats.shopCount} ratings)',
            style: TextStyle(fontSize: 16, color: context.boba.onImage),
          ),
        ],
      );
    },
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
        bgUrl = medias.first.imageUrl;
      }

      return InkWell(
        onTap: medias.isNotEmpty
            ? () => onTapWithMedias(medias)
            : null, // ⬅️ wire here
        child: Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(color: context.boba.surfaceAlt),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bgUrl != null)
                CachedNetworkImage(
                  imageUrl: bgUrl,
                  fit: BoxFit.cover,
                  color: context.boba.imageScrim.withValues(alpha: 0.35),
                  colorBlendMode: BlendMode.darken,
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        context.boba.imageScrim.withValues(alpha: 0.54),
                      ],
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

Widget buildBannerContent(
  BuildContext context,
  Brand brand,
  Future<BrandStats> statsFuture,
  Shop? userShop,
) {
  final collectedLabel = userShop == null ? 'Not collected' : 'In dex ✓';
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end, // bottom align children
      children: [
        Hero(
          tag: BrandMark.heroTag(brand.slug),
          child: BrandMark(
            name: brand.display,
            slug: brand.slug,
            iconPath: brand.iconPath,
            fit: BoxFit.contain,
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
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.boba.onImage,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: context.boba.imageScrim.withValues(alpha: 0.54),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BobaChip(
                  label: collectedLabel,
                  selected: userShop != null,
                ),
              ),
              const SizedBox(height: 4),
              _buildGlobalRatings(brand, statsFuture),
            ],
          ),
        ),
      ],
    ),
  );
}

const _visitMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String? _visitSince(Shop shop) {
  final created = shop.createdAt;
  if (created.millisecondsSinceEpoch <= 0) return null;
  return 'Since ${_visitMonths[created.month - 1]} ${created.year}';
}

class _YourVisitCard extends StatelessWidget {
  const _YourVisitCard({required this.shop, required this.onEdit});

  final Shop shop;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final notes = shop.notes?.trim() ?? '';
    final since = _visitSince(shop);
    return BobaCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your visit',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (since != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        since,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.boba.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              BobaButton(
                label: 'Edit',
                variant: BobaButtonVariant.tertiary,
                size: BobaButtonSize.small,
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: BobaSpace.x3),
          RatingText(value: shop.rating, size: RatingTextSize.large),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: BobaSpace.x2),
            Text(
              notes,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

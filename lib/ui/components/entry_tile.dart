import 'package:bobadex/helpers/url_helper.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.shop,
    required this.columns,
    required this.useIcons,
    required this.onTap,
  });

  final Shop shop;
  final int columns;
  final bool useIcons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shopId = shop.id;
    final brand = context.select<BrandState, Brand?>(
      (s) => s.getBrand(shop.brandSlug),
    );
    final bannerPath = context.select<ShopMediaState, String?>(
      (s) => shopId == null ? null : s.getBannerPath(shopId),
    );
    final drinkCount = context.select<DrinkState, int>(
      (s) => shopId == null ? 0 : s.drinksFor(shopId).length,
    );
    final rpcCount = context.select<ShopState, int>(
      (s) => shopId == null ? 0 : s.countsForShop(shopId).total,
    );
    final count = drinkCount > 0 ? drinkCount : rpcCount;
    final useMascots = context.select<UserState, bool>(
      (s) => s.current.useMascots,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    const spacing = 8.0;
    final itemWidth = (screenWidth - (spacing * (columns + 1))) / columns;
    final scale = (itemWidth / 120).clamp(0.75, 1.4);
    final brandIconPath = brand?.iconPath;
    final hasBanner = bannerPath != null && bannerPath.isNotEmpty;
    final hasBrandIcon = brandIconPath != null && brandIconPath.isNotEmpty;
    final brandLabel = brand?.display ?? shop.name;
    final seed = shop.brandSlug ?? brandLabel;
    final displayUrl = hasBanner
        ? publicUrl('media-uploads', thumbPath(bannerPath, 512))
        : (useMascots && hasBrandIcon
              ? publicUrl('shop-media', thumbPath(brandIconPath, 512))
              : null);

    return useIcons
        ? _IconEntry(
            shop: shop,
            brandLabel: brandLabel,
            brandIconPath: brandIconPath,
            count: count,
            scale: scale,
            columns: columns,
            onTap: onTap,
          )
        : _PhotoEntry(
            shop: shop,
            brandLabel: brandLabel,
            seed: seed,
            displayUrl: displayUrl,
            count: count,
            scale: scale,
            onTap: onTap,
          );
  }
}

class _IconEntry extends StatelessWidget {
  const _IconEntry({
    required this.shop,
    required this.brandLabel,
    required this.brandIconPath,
    required this.count,
    required this.scale,
    required this.columns,
    required this.onTap,
  });

  final Shop shop;
  final String brandLabel;
  final String? brandIconPath;
  final int count;
  final double scale;
  final int columns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return BobaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(BobaSpace.x3),
      accentSpine: tokens.isDark ? tokens.accent : tokens.accentInk,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 13 * scale),
              ),
              const SizedBox(height: 4),
              RatingText(value: shop.rating, size: RatingTextSize.small),
              const SizedBox(height: 2),
              Row(
                children: [
                  SvgPicture.asset(
                    'lib/assets/icons/boba1.svg',
                    width: 13 * scale,
                    height: 13 * scale,
                    colorFilter: ColorFilter.mode(
                      context.boba.inkMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('$count', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: BrandMark(
              name: brandLabel,
              slug: shop.brandSlug,
              iconPath: brandIconPath,
              size: (columns == 2 ? 78 : 46) * scale,
              fit: BoxFit.contain,
            ),
          ),
          if (shop.isFavorite)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.favorite_rounded,
                size: 16 * scale,
                color: context.boba.heart,
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoEntry extends StatelessWidget {
  const _PhotoEntry({
    required this.shop,
    required this.brandLabel,
    required this.seed,
    required this.displayUrl,
    required this.count,
    required this.scale,
    required this.onTap,
  });

  final Shop shop;
  final String brandLabel;
  final String seed;
  final String? displayUrl;
  final int count;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return BobaCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          displayUrl != null
              ? CachedNetworkImage(
                  imageUrl: displayUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      ColoredBox(color: tokens.surfaceAlt),
                  errorWidget: (context, url, error) => BrandLettering(
                    name: brandLabel,
                    seed: seed,
                    expand: true,
                    circular: false,
                  ),
                )
              : BrandLettering(
                  name: brandLabel,
                  seed: seed,
                  expand: true,
                  circular: false,
                ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.imageScrim.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  8 * scale,
                  16 * scale,
                  8 * scale,
                  10 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.onImage,
                        fontWeight: FontWeight.w700,
                        fontSize: 14 * scale,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12 * scale,
                          color: tokens.onImage,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: TextStyle(color: tokens.onImage),
                        ),
                        const SizedBox(width: 10),
                        SvgPicture.asset(
                          'lib/assets/icons/boba1.svg',
                          width: 12 * scale,
                          height: 12 * scale,
                          colorFilter: ColorFilter.mode(
                            tokens.onImage,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('$count', style: TextStyle(color: tokens.onImage)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (shop.isFavorite)
            Positioned(
              top: 10,
              right: 10,
              child: Icon(
                Icons.favorite_rounded,
                size: 18 * scale,
                color: tokens.heart,
              ),
            ),
        ],
      ),
    );
  }
}

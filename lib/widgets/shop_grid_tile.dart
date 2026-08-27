import 'package:bobadex/helpers/url_helper.dart';
import 'package:bobadex/models/brand.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/drink_state.dart';
import 'package:bobadex/state/shop_media_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/widgets/icon_pic.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ShopGridTile extends StatelessWidget {
  final Shop shop;
  final int columns;
  final bool useIcons;
  final MaterialColor themeColor;
  final VoidCallback onTap;

  const ShopGridTile({
    super.key,
    required this.shop,
    required this.columns,
    required this.useIcons,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shopId = shop.id;
    final brand = context.select<BrandState, Brand?>((s) => s.getBrand(shop.brandSlug));
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

    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 4.0;
    const baseTileWidth = 120.0;
    final itemWidth = (screenWidth - (spacing * (columns + 1))) / columns;
    final scaleFactor = itemWidth / baseTileWidth;
    final imageScale = columns == 2 ? scaleFactor * 1.2 : scaleFactor;
    final textScale = columns == 2 ? scaleFactor * 1 : scaleFactor;

    final brandIconPath = brand?.iconPath;
    final hasBanner = bannerPath != null && bannerPath.isNotEmpty;
    final hasBrandIcon = brandIconPath != null && brandIconPath.isNotEmpty;
    final displayUrl = hasBanner
        ? publicUrl('media-uploads', thumbPath(bannerPath, 512))
        : (hasBrandIcon
            ? publicUrl('shop-media', thumbPath(brandIconPath, 512))
            : null);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        color: useIcons
            ? themeColor.shade200
            : Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: useIcons
            ? Padding(
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
                                const SizedBox(width: 2),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 12 * textScale),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                SvgPicture.asset(
                                  'lib/assets/icons/boba1.svg',
                                  width: 13 * textScale,
                                  height: 13 * textScale,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  count.toString(),
                                  style: TextStyle(fontSize: 12 * textScale),
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconPic(path: brandIconPath, size: 55 * imageScale),
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
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    displayUrl != null
                        ? CachedNetworkImage(
                            imageUrl: displayUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => Image.asset(
                              'lib/assets/default_icon.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : Image.asset(
                            'lib/assets/default_icon.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 10 * textScale,
                          horizontal: 8 * textScale,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              shop.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * textScale,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2 * textScale),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'lib/assets/icons/star.svg',
                                  width: 12 * textScale,
                                  height: 12 * textScale,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop.rating.toStringAsFixed(1),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                SvgPicture.asset(
                                  'lib/assets/icons/boba1.svg',
                                  width: 12 * textScale,
                                  height: 12 * textScale,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  count.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (shop.isFavorite)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: SvgPicture.asset(
                          'lib/assets/icons/heart.svg',
                          width: 18 * textScale,
                          height: 18 * textScale,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

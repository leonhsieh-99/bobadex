import 'package:bobadex/models/friends_shop.dart';
import 'package:bobadex/models/shop.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/pages/shop_detail_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/avatar_stack.dart';
import 'package:bobadex/ui/components/boba_button.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/rating_comparison_bar.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/components/section_header.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SharedBrandPage extends StatelessWidget {
  const SharedBrandPage({super.key, required this.shop, this.mostDrinksUser});

  final FriendsShop shop;
  final String? mostDrinksUser;

  @override
  Widget build(BuildContext context) {
    final friendState = context.watch<FriendState>();
    final userState = context.watch<UserState>();
    final brand = context.read<BrandState>().getBrand(shop.brandSlug);
    final currentId = userState.current.id;
    final myShop = context.select<ShopState, Shop?>(
      (s) => s.getShopByBrand(currentId, shop.brandSlug),
    );
    final drinkCount = myShop == null
        ? 0
        : context.select<ShopState, int>(
            (s) => s.countsForShop(myShop.id ?? '').total,
          );

    String nameFor(String id) {
      if (id == currentId) return 'You';
      try {
        return friendState.getDisplayName(id);
      } catch (_) {
        return 'Friend';
      }
    }

    String? pathFor(String id) {
      if (id == currentId) return userState.current.profileImagePath;
      try {
        return friendState.getImagePath(id);
      } catch (_) {
        return null;
      }
    }

    final sorted = shop.friendsInfo.entries.toList()
      ..sort((a, b) => b.value.rating.compareTo(a.value.rating));

    final markers = sorted
        .map(
          (e) => RatingComparisonMarker(
            id: e.key,
            rating: e.value.rating,
            path: pathFor(e.key),
            initials: nameFor(e.key),
            isYou: e.key == currentId,
          ),
        )
        .toList();

    final photoPaths = <String>[];
    for (final info in shop.friendsInfo.values) {
      photoPaths.addAll(info.imagePaths);
      final path = info.filePath?.trim();
      if (path != null && path.isNotEmpty && !photoPaths.contains(path)) {
        photoPaths.add(path);
      }
    }

    final friendCount = shop.friendsInfo.length;
    final display = brand?.display ?? shop.name;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: GestureDetector(
              onTap: brand == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BrandDetailsPage(brand: brand),
                      ),
                    ),
              child: BrandMark(
                name: display,
                slug: shop.brandSlug,
                iconPath: brand?.iconPath ?? shop.iconPath,
                size: 96,
              ),
            ),
          ),
          const SizedBox(height: BobaSpace.x3),
          Text(
            display,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: BobaSpace.x1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingText(value: shop.avgRating, size: RatingTextSize.large),
              const SizedBox(width: 8),
              Text(
                'from $friendCount friend${friendCount == 1 ? '' : 's'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.boba.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: BobaSpace.x2),
          Center(
            child: AvatarStack(
              paths: shop.friendsInfo.keys.map(pathFor).toList(),
              size: 28,
            ),
          ),
          const SizedBox(height: BobaSpace.x4),
          if (myShop != null)
            BobaCard(
              variant: BobaCardVariant.inset,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ShopDetailPage(shopId: myShop.id!, userId: currentId),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Your entry · ${myShop.rating.toStringAsFixed(1)} ★ · $drinkCount drinks',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.boba.inkMuted,
                  ),
                ],
              ),
            )
          else if (brand != null)
            BobaButton(
              label: 'Add to your dex',
              expanded: true,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BrandDetailsPage(brand: brand),
                ),
              ),
            ),
          const SizedBox(height: BobaSpace.x5),
          RatingComparisonBar(markers: markers),
          const SectionHeader(
            title: "Friends' entries",
            padding: EdgeInsets.only(top: 20, bottom: 8),
          ),
          if (sorted.isEmpty)
            Text('No ratings yet from friends', style: context.bobaText.empty)
          else
            BobaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    _FriendEntryRow(
                      userId: sorted[i].key,
                      info: sorted[i].value,
                      displayName: nameFor(sorted[i].key),
                      imagePath: pathFor(sorted[i].key),
                      isYou: sorted[i].key == currentId,
                      isCrown: sorted[i].key == mostDrinksUser,
                    ),
                    if (i != sorted.length - 1)
                      Divider(
                        height: 1,
                        thickness: BobaStroke.card,
                        color: context.boba.outline,
                      ),
                  ],
                ],
              ),
            ),
          if (photoPaths.isNotEmpty) ...[
            const SectionHeader(
              title: 'Photos from friends',
              padding: EdgeInsets.only(top: 20, bottom: 8),
            ),
            SizedBox(
              height: 88,
              child: HorizontalPhotoPreview(
                shopMediaList: photoPaths
                    .map(
                      (p) =>
                          ShopMedia.galleryViewMedia(imagePath: p, comment: ''),
                    )
                    .toList(),
                height: 88,
                width: 72,
                maxPreview: 6,
                showUserInfo: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendEntryRow extends StatelessWidget {
  const _FriendEntryRow({
    required this.userId,
    required this.info,
    required this.displayName,
    required this.imagePath,
    required this.isYou,
    required this.isCrown,
  });

  final String userId;
  final FriendShopInfo info;
  final String displayName;
  final String? imagePath;
  final bool isYou;
  final bool isCrown;

  @override
  Widget build(BuildContext context) {
    final friendState = context.read<FriendState>();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isCrown,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: isYou
                  ? null
                  : () {
                      try {
                        final friend = friendState.getFriend(userId);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AccountViewPage(userId: userId, user: friend),
                          ),
                        );
                      } catch (_) {}
                    },
              child: ThumbPic(path: imagePath, size: 40, initials: displayName),
            ),
            if (isCrown)
              Positioned(
                right: -2,
                bottom: -2,
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: context.boba.star,
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (info.isFavorite) ...[
              const SizedBox(width: 6),
              Icon(Icons.favorite_rounded, size: 16, color: context.boba.heart),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            RatingText(value: info.rating, size: RatingTextSize.small),
            const SizedBox(width: 8),
            Text(
              '${info.drinksTried} drinks',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: context.boba.inkMuted),
            ),
          ],
        ),
        children: [
          if ((info.note ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(info.note!),
              ),
            ),
          if (info.top3Drinks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top drinks',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  for (final drink in info.top3Drinks)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              drink.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          RatingText(
                            value: drink.rating,
                            size: RatingTextSize.small,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

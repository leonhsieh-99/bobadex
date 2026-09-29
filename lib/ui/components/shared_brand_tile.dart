import 'package:bobadex/models/friends_shop.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/avatar_stack.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SharedBrandTile extends StatelessWidget {
  const SharedBrandTile({super.key, required this.shop, this.onTap});

  final FriendsShop shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final brand = context.read<BrandState>().getBrand(shop.brandSlug);
    final display = brand?.display ?? shop.name;
    final currentId = context.select<UserState, String>((s) => s.current.id);
    final mine = context.select<ShopState, double?>(
      (s) => s.getShopByBrand(currentId, shop.brandSlug)?.rating,
    );
    final friendState = context.read<FriendState>();
    final me = context.read<UserState>().current;
    final avatarPaths = shop.friendsInfo.keys.map((id) {
      if (id == currentId) return me.profileImagePath;
      try {
        return friendState.getImagePath(id);
      } catch (_) {
        return null;
      }
    }).toList();

    return SizedBox.expand(
      child: BobaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(BobaSpace.x3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          BrandMark(
            name: display,
            slug: shop.brandSlug,
            iconPath: brand?.iconPath ?? shop.iconPath,
            size: 56,
          ),
          const SizedBox(height: BobaSpace.x2),
          Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RatingText(value: shop.avgRating, size: RatingTextSize.small),
              const SizedBox(width: 4),
              Text(
                'avg',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tokens.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: BobaSpace.x2),
          AvatarStack(paths: avatarPaths, size: 22, maxVisible: 3),
          if (mine != null && mine > 0) ...[
            const SizedBox(height: BobaSpace.x1),
            Text(
              'You: ${mine.toStringAsFixed(1)}',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

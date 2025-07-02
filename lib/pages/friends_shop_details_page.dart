import 'package:bobadex/config/constants.dart';
import 'package:bobadex/models/friends_shop.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/friend_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsShopDetailsPage extends StatelessWidget {
  final FriendsShop shop;
  final String? mostDrinksUser;

  const FriendsShopDetailsPage({
    super.key,
    required this.shop,
    this.mostDrinksUser,
  });

  String getThumbUrl(imagePath) {
    return imagePath != null && imagePath!.isNotEmpty
        ? Supabase.instance.client.storage.from('media-uploads').getPublicUrl('thumbs/${imagePath!.trim()}')
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final friendState = context.read<FriendState>();
    final userState = context.read<UserState>();
    final brandState = context.read<BrandState>();
    final themeColor = Constants.getThemeColor(userState.user.themeSlug);

    // Split crown/mostDrinks entry out
    final entries = shop.friendsInfo.entries.toList();
    MapEntry<String, FriendShopInfo>? crownEntry;
    List<MapEntry<String, FriendShopInfo>> rest;

    if (mostDrinksUser != null) {
      final matches = entries.where((e) => e.key == mostDrinksUser).toList();
      crownEntry = matches.isNotEmpty ? matches.first : null;
      rest = entries.where((e) => e.key != mostDrinksUser).toList();
    } else {
      crownEntry = null;
      rest = entries;
    }

    Widget glowCard({required Widget child, double borderRadius = 12, double glowRadius = 10}) {
      return Container(
        clipBehavior: Clip.none,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // This gives you a bright golden/yellow glow
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.6),
              blurRadius: glowRadius,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: glowRadius * 2,
              spreadRadius: 4,
            ),
          ],
        ),
        child: child, // the Card itself
      );
    }

    // Builder for each tile
    Widget buildFriendTile(MapEntry<String, dynamic> e, {bool isCrown = false}) {
      final userId = e.key;
      final info = e.value;
      final rating = info.rating;
      final note = info.note;
      final isFavorite = info.isFavorite;
      final top3Drinks = info.top3Drinks;
      final drinkCount = info.drinksTried;

      String displayName;
      String thumbUrl;
      if (userId == userState.user.id) {
        displayName = 'You';
        thumbUrl = userState.user.thumbUrl;
      } else {
        displayName = friendState.getDisplayName(userId);
        thumbUrl = friendState.getThumbUrl(userId);
      }

      Widget baseCard() => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: isCrown,
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: userId == Supabase.instance.client.auth.currentUser!.id
                    ? null
                    : () =>  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AccountViewPage(user: friendState.getFriend(userId)))
                    ),
                  child: CircleAvatar(
                    backgroundImage: thumbUrl.isNotEmpty
                        ? CachedNetworkImageProvider(thumbUrl)
                        : null,
                    radius: isCrown ? 28 : 24,
                    child: thumbUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                ),
                if (isCrown)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.emoji_events, color: Colors.amber, size: 22), // crown
                  ),
              ],
            ),
            title: Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  child: Text(
                    displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (isFavorite == true)
                  Icon(Icons.star, color: Colors.orange, size: 18),
              ],
            ),
            subtitle: Row(
              children: [
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                if (drinkCount > 0)
                  Row(
                    children: [
                      Icon(Icons.local_drink, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 2),
                      Text('$drinkCount drinks'),
                    ],
                  ),
              ],
            ),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((note ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text(note, style: TextStyle(fontWeight: FontWeight.w400)),
                    ),
                  if (top3Drinks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top Drinks', style: TextStyle(fontWeight: FontWeight.w500)),
                          ...top3Drinks.map((drink) => Row(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                child: Text(
                                  drink.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.star, size: 15, color: Colors.orange),
                              Text(drink.rating.toStringAsFixed(1)),
                            ],
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ]
          ),
        ),
      );
      return isCrown
        ? glowCard(child: baseCard())
        : baseCard();
    }

    // Build the list
    List<Widget> friendTiles = [];
    if (crownEntry != null) {
      friendTiles.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
          child: buildFriendTile(crownEntry, isCrown: true),
        ),
      );
      if (rest.isNotEmpty) {
        friendTiles.add(const Divider(thickness: 1, height: 24));
      }
    }
    friendTiles.addAll(rest.map((entry) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12.0),
      child: buildFriendTile(entry),
    )));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brandState.getBrand(shop.brandSlug)!)),
                ),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: themeColor.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: (shop.iconPath.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: brandState.getBrand(shop.brandSlug)!.thumbUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'lib/assets/default_icon.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              shop.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Average Rating: ${shop.avgRating.toStringAsFixed(1)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text('Friends Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...friendTiles,
            if (shop.friendsInfo.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No ratings yet from friends'),
              ),
          ],
        ),
      ),
    );
  }
}

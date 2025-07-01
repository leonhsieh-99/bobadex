import 'package:bobadex/models/friends_shop.dart';
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

    // Builder for each tile
    Widget buildFriendTile(MapEntry<String, dynamic> e, {bool isCrown = false}) {
      final userId = e.key;
      final info = e.value;
      final rating = info.rating;
      final note = info.note;
      final isFavorite = info.isFavorite;
      final top5Drinks = info.top5Drinks;
      final friendShopUrl = info.thumbUrl;
      final drinkCount = top5Drinks.length;

      String displayName;
      String thumbUrl;
      if (userId == userState.user.id) {
        displayName = 'You';
        thumbUrl = userState.user.thumbUrl;
      } else {
        displayName = friendState.getDisplayName(userId);
        thumbUrl = friendState.getThumbUrl(userId);
      }

      return Card(
        elevation: isCrown ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCrown
              ? BorderSide(color: Colors.amber, width: 2)
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: isCrown
            ? const EdgeInsets.only(bottom: 18) // Extra space below crown
            : const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          leading: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                backgroundImage: thumbUrl.isNotEmpty
                    ? CachedNetworkImageProvider(thumbUrl)
                    : null,
                radius: isCrown ? 28 : 24,
                child: thumbUrl.isEmpty ? const Icon(Icons.person) : null,
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
                    Text('$drinkCount tried'),
                  ],
                ),
            ],
          ),
            children: [
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 100.0), // Leave space for the thumb
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((note ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Text('Note: $note'),
                          ),
                        if (top5Drinks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Top Drinks:', style: TextStyle(fontWeight: FontWeight.w500)),
                                ...top5Drinks.map((drink) => Row(
                                  children: [
                                    if (drink.isFavorite == true)
                                      Icon(Icons.favorite, color: Colors.pink, size: 16),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                      child: Text(
                                        drink.name,
                                        style: TextStyle(
                                          fontWeight: drink.isFavorite == true ? FontWeight.bold : FontWeight.normal,
                                        ),
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
                  ),
                  if (friendShopUrl.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: friendShopUrl,
                          width: 84,
                          height: 84,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
        ),
      );
    }

    // Build the list
    List<Widget> friendTiles = [];
    if (crownEntry != null) {
      friendTiles.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: buildFriendTile(crownEntry, isCrown: true),
        ),
      );
      if (rest.isNotEmpty) {
        friendTiles.add(const Divider(thickness: 1, height: 24));
      }
    }
    friendTiles.addAll(rest.map((entry) => buildFriendTile(entry)));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
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
            const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: shop.gallery.isEmpty
                ? const Center(child: Text('No photos yet'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shop.gallery.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final img = shop.gallery[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: getThumbUrl(img),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 24),
            const Text('Friends Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
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

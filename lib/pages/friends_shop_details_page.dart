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

  const FriendsShopDetailsPage({
    super.key,
    required this.shop,
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
    return Scaffold(
      appBar: AppBar(
      ),
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
                  )
              ),
            ),
            const SizedBox(height: 20),
            Text(
              shop.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Average Rating: ${shop.avgRating.toStringAsFixed(1)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 100,
              child: shop.gallery.isEmpty
                ? Center(child: Text('No photos yet'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shop.gallery.length,
                    separatorBuilder: (_, __) => SizedBox(width: 8),
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
            Text('Friends Ratings', style: TextStyle(fontWeight: FontWeight.bold)),
            ...shop.friendsRatings.entries.map((e) {
              final userId = e.key;
              final rating = e.value;

              String displayName;
              String thumbUrl;

              if (userId == userState.user.id) {
                displayName = 'You';
                thumbUrl = userState.user.thumbUrl;
              } else {
                displayName = friendState.getDisplayName(userId);
                thumbUrl = friendState.getThumbUrl(userId);
              }

              return ListTile(
                leading: thumbUrl.isNotEmpty
                    ? CircleAvatar(backgroundImage: CachedNetworkImageProvider(thumbUrl))
                    : CircleAvatar(child: Icon(Icons.person)),
                title: Text(displayName),
                trailing: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              );
            }),

            if (shop.friendsRatings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('No ratings yet from friends'),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:bobadex/widgets/number_rating.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedEventCard extends StatelessWidget {
  final FeedEvent event;

  const FeedEventCard({super.key, required this.event});

  String _eventTypeToText(String eventType) {
    switch (eventType) {
      case 'shop_add': return 'added a shop ';
      case 'drink_add': return 'added a drink ';
      case 'achievement': return 'earned a badge ';
      default: return eventType;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${dt.month}/${dt.day}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final brandState = context.read<BrandState>();
    final payload = event.payload;
    final avatarUrl = (payload['user_avatar'] ?? '') as String;
    final userName = (payload['user_name'] ?? 'Unknown user').toString();
    final name = event.eventType == 'shop_add'
      ? payload['shop_name']
      : event.eventType == 'achievement'
        ? payload['achievement_name']
        : 'Uknown';
    final images = (payload['images'] as List?) ?? [];
    final rating = double.tryParse('${payload['rating'] ?? ''}') ?? 0.0;
    final createdAt = event.createdAt ?? DateTime.now();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThumbPic(url: avatarUrl),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _eventTypeToText(event.eventType),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        (event.eventType != 'shop_add')
                          ? Text(
                            name,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                          : TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.all(0),
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              final slug = payload['slug']?.toString() ?? '';
                              if (slug.isNotEmpty) {
                                final brand = brandState.getBrand(slug);
                                if (brand != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand))
                                  );
                                }
                              }
                            },
                            child: Text(
                              name,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          )
                      ],
                    )
                  ],
                ),
                Spacer(),
                if (event.eventType == 'shop_add')
                  NumberRating(rating: rating.toString())
              ],
            ),
            const SizedBox(height: 10),

            // Main content
            if (payload['shop_name'] != null && payload['notes'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  payload['notes'] ?? '',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            if (images.isNotEmpty)
              HorizontalPhotoPreview(
                shopMediaList: images.map((img) {
                  final path = img['path']?.toString() ?? '';
                  final comment = img['comment']?.toString() ?? '';
                  return ShopMedia.galleryViewMedia(imagePath: path, comment: comment);
                }).toList(),
              ),
            Row(
              children: [
                Spacer(),
                Text(
                  _formatTimeAgo(createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.green.shade500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class FeedEventCardSkeleton extends StatelessWidget {
  const FeedEventCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gray circle for avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                // Gray lines for username and event
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 14,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(
                      width: 60,
                      height: 12,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
                Spacer(),
                // Gray bar for date
                Container(
                  width: 40,
                  height: 12,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Gray box for notes
            Container(
              width: double.infinity,
              height: 16,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),

            // Gray rectangles for images
            Row(
              children: List.generate(3, (i) => 
                Container(
                  width: 56,
                  height: 56,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              ),
            )
          ],
        ),
      ),
    );
  }
}

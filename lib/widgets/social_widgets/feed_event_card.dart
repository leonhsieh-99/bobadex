import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:bobadex/widgets/number_rating.dart';
import 'package:bobadex/widgets/social_widgets/feed_card_options.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FeedEventCard extends StatelessWidget {
  final FeedEvent event;
  final FeedCardVariant variant;

  const FeedEventCard({
    super.key,
    required this.event,
    this.variant = FeedCardVariant.friends,
  });

  String _verb(String type, bool hidden) {
    switch (type) {
      case 'shop_add': return 'added a shop';
      case 'drink_add': return 'added a drink';
      case 'achievement': return hidden ? 'unlocked a hidden achievement' : 'unlocked an achievement';
      default: return type;
    }
  }

  IconData _verbIcon(String type, bool hidden) {
    switch (type) {
      case 'shop_add': return Icons.storefront_rounded;
      case 'drink_add': return Icons.local_drink_rounded;
      case 'achievement': return hidden ? Icons.lock_outline : Icons.emoji_events_outlined;
      default: return Icons.bolt; // fallback
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final opts = FeedCardOptions.forVariant(variant);
    final theme = Theme.of(context);
    final brandState = context.read<BrandState>();
    final p = event.payload;
    final user = event.feedUser;

    final isHidden = p['is_hidden'] == true;
    final titleText = switch (event.eventType) {
      'shop_add'    => (p['shop_name'] ?? 'Unknown') as String,
      'achievement' => (p['achievement_name'] ?? 'Achievement') as String,
      _             => 'Details'
    };
    final rating = double.tryParse('${p['rating'] ?? ''}') ?? 0.0;
    final images = (p['images'] as List?) ?? const [];
    final shopName = (p['shop_name'] as String?)?.trim() ?? '';
    final brandSlug = (event.brandSlug ?? '').trim();

    // --- header row (friends/brand) OR verb pill (userProfile) ----------------
    Widget headerArea;
    if (opts.showVerbPill) {
      final brandState = context.read<BrandState>();
      headerArea = Row(
        children: [
          _VerbPill(
            icon: _verbIcon(event.eventType, isHidden),
            text: _verb(event.eventType, isHidden),
          ),
          const SizedBox(width: 8),
          if (event.eventType == 'shop_add' && shopName.isNotEmpty)
            _ShopLink(
              text: shopName,
              onTap: (brandSlug.isNotEmpty && brandState.getBrand(brandSlug) != null)
                  ? () {
                      final brand = brandState.getBrand(brandSlug)!;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)),
                      );
                    }
                  : null,
            ),
        ],
      );
    } else {
      headerArea = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (opts.showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => AccountViewPage(userId: user.id, user: user))),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (user.thumbUrl.isNotEmpty) ? NetworkImage(user.thumbUrl) : null,
                  child: (user.thumbUrl.isEmpty) ? Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?') : null,
                ),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (opts.showUsername)
                  Text(
                    user.firstName,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),

                if (opts.showVerbInline)
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              // Verb
                              TextSpan(
                                text: _verb(event.eventType, isHidden),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),

                              // Space + clickable shop name (shop_add)
                              if (event.eventType == 'shop_add') const TextSpan(text: ' '),
                              if (event.eventType == 'shop_add')
                                TextSpan(
                                  text: titleText, // shop name
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                  recognizer: (() {
                                    final slug = (event.brandSlug ?? '').trim();
                                    final brand = slug.isNotEmpty ? brandState.getBrand(slug) : null;
                                    if (brand == null) return null;
                                    return TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)),
                                        );
                                      };
                                  })(),
                                ),

                              // Space + bold achievement name (non-clickable)
                              if (event.eventType == 'achievement' && !isHidden && titleText.isNotEmpty)
                                const TextSpan(text: ' '),
                              if (event.eventType == 'achievement' && !isHidden && titleText.isNotEmpty)
                                TextSpan(
                                  text: titleText,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (event.eventType == 'shop_add')
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: NumberRating(rating: rating == 0 ? 'N/A' : rating.toString()),
            ),
        ],
      );
    }

    // --- body (notes + images OR achievement row) -----------------------------
    final body = switch (event.eventType) {
      'achievement' => _AchievementRow(
        description: isHidden ? '? ? ?' : (p['achievement_desc'] ?? '') as String,
        iconAssetPath: (p['achievement_badge_path'] ?? '') as String,
      ),
      'shop_add' => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((p['notes'] ?? '').toString().trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                p['notes'],
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (images.isNotEmpty)
            HorizontalPhotoPreview(
              shopMediaList: images.map((img) {
                final path = (img['path'] ?? '').toString();
                final comment = (img['comment'] ?? '').toString();
                return ShopMedia.galleryViewMedia(imagePath: path, comment: comment);
              }).toList(),
              height: 110,
              width: 90,
              showUserInfo: false,
            ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };

    // --- card shell -----------------------------------------------------------
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: opts.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headerArea,
            const SizedBox(height: 10),
            body,
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                Text(
                  _timeAgo(event.createdAt),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary.withOpacity(0.75)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= helpers =================

class _VerbPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _VerbPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final String description;
  final String iconAssetPath;
  const _AchievementRow({required this.description, required this.iconAssetPath});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: (iconAssetPath.isNotEmpty)
              ? AssetImage(iconAssetPath)
              : const AssetImage('lib/assets/badges/default_badge.png'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

class _ShopLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _ShopLink({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onTap == null
                ? theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
                : theme.colorScheme.primary,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
        ]
      ],
    );

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(onTap == null ? 0.4 : 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: child,
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

import 'package:bobadex/helpers/initials_helper.dart';
import 'package:bobadex/models/feed_event.dart';
import 'package:bobadex/models/shop_media.dart';
import 'package:bobadex/pages/account_view_page.dart';
import 'package:bobadex/pages/brand_details_page.dart';
import 'package:bobadex/state/brand_state.dart';
import 'package:bobadex/state/shop_state.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/boba_chip.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/components/skeleton_box.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/brand_mark.dart';
import 'package:bobadex/widgets/image_widgets/horizontal_photo_preview.dart';
import 'package:bobadex/widgets/social_widgets/feed_card_options.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BobaSpace.x1,
        BobaSpace.x4,
        BobaSpace.x1,
        BobaSpace.x2,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: context.boba.inkMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

List<({String label, List<FeedEvent> events})> groupFeedByDay(
  List<FeedEvent> events,
) {
  final groups = <({String label, List<FeedEvent> events})>[];
  String? current;
  for (final event in events) {
    final label = feedDayLabel(event.createdAt);
    if (current != label) {
      groups.add((label: label, events: [event]));
      current = label;
    } else {
      groups.last.events.add(event);
    }
  }
  return groups;
}

String feedDayLabel(DateTime raw) {
  final dt = raw.toLocal();
  final day = DateTime(dt.year, dt.month, dt.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  const months = [
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
  return '${months[day.month - 1]} ${day.day}';
}

class FeedDaySliverList extends StatelessWidget {
  const FeedDaySliverList({
    super.key,
    required this.events,
    this.variant = FeedCardVariant.friends,
    this.trailing,
  });

  final List<FeedEvent> events;
  final FeedCardVariant variant;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final groups = groupFeedByDay(events);
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == groups.length) return trailing;
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DayHeader(label: group.label),
              BobaCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < group.events.length; i++) ...[
                      FeedEventRow(event: group.events[i], variant: variant),
                      if (i != group.events.length - 1)
                        Divider(
                          height: 1,
                          thickness: BobaStroke.card,
                          color: context.boba.outline,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }, childCount: groups.length + (trailing != null ? 1 : 0)),
    );
  }
}

class FeedDayColumn extends StatelessWidget {
  const FeedDayColumn({
    super.key,
    required this.events,
    this.variant = FeedCardVariant.friends,
    this.trailing,
  });

  final List<FeedEvent> events;
  final FeedCardVariant variant;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final groups = groupFeedByDay(events);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DayHeader(label: group.label),
                BobaCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < group.events.length; i++) ...[
                        FeedEventRow(event: group.events[i], variant: variant),
                        if (i != group.events.length - 1)
                          Divider(
                            height: 1,
                            thickness: BobaStroke.card,
                            color: context.boba.outline,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ?trailing,
      ],
    );
  }
}

class FeedEventRow extends StatelessWidget {
  const FeedEventRow({
    super.key,
    required this.event,
    this.variant = FeedCardVariant.friends,
  });

  final FeedEvent event;
  final FeedCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final brandState = context.read<BrandState>();
    final payload = event.payload;
    final user = event.feedUser;
    final hidden = payload['is_hidden'] == true;
    final slug = (event.brandSlug ?? '').trim();
    final brand = slug.isEmpty ? null : brandState.getBrand(slug);
    final shopName = (payload['shop_name'] as String?)?.trim() ?? '';
    final drinkName = (payload['drink_name'] as String?)?.trim() ?? '';
    final brandLabel =
        brand?.display ?? (shopName.isNotEmpty ? shopName : 'a brand');
    final rating = double.tryParse('${payload['rating'] ?? ''}');
    final notes = (payload['notes'] ?? '').toString().trim();
    final images = (payload['images'] as List?) ?? const [];
    final actor = user.firstName.trim().isNotEmpty
        ? user.firstName
        : (user.displayName.trim().isNotEmpty
              ? user.displayName
              : user.username);

    void openBrand() {
      if (brand == null) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => BrandDetailsPage(brand: brand)));
    }

    void openProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AccountViewPage(userId: user.id, user: user),
        ),
      );
    }

    void openAchievement() {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          final name = hidden
              ? 'Hidden badge'
              : (payload['achievement_name'] ?? 'Achievement') as String;
          final desc = hidden
              ? 'Keep collecting to reveal this one.'
              : (payload['achievement_desc'] ?? '') as String;
          final icon = (payload['achievement_badge_path'] ?? '') as String;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: ctx.boba.surfaceAlt,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      icon.isNotEmpty
                          ? icon
                          : 'lib/assets/badges/first_sip.png',
                      errorBuilder: (_, _, _) =>
                          Image.asset('lib/assets/badges/first_sip.png'),
                    ),
                  ),
                ),
                const SizedBox(height: BobaSpace.x3),
                Text(name, style: Theme.of(ctx).textTheme.titleMedium),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: BobaSpace.x2),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      ctx,
                    ).textTheme.bodyMedium?.copyWith(color: ctx.boba.inkMuted),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    final titleStyle = Theme.of(context).textTheme.bodyMedium;
    final muted = titleStyle?.copyWith(color: tokens.inkMuted);
    final bold = titleStyle?.copyWith(
      color: tokens.ink,
      fontWeight: FontWeight.w700,
    );

    final title = Text.rich(
      TextSpan(
        children: _titleSpans(
          variant: variant,
          type: event.eventType,
          actor: actor,
          brandLabel: brandLabel,
          drinkName: drinkName,
          shopName: shopName.isNotEmpty ? shopName : brandLabel,
          achievementName: (payload['achievement_name'] ?? 'a badge') as String,
          hidden: hidden,
          muted: muted,
          bold: bold,
        ),
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );

    final Widget leading;
    if (variant == FeedCardVariant.brand) {
      leading = ThumbPic(
        path: user.profileImagePath,
        size: 44,
        initials: initialFrom(
          firstName: user.firstName,
          displayName: user.displayName,
          username: user.username,
        ),
        onTap: openProfile,
      );
    } else if (event.eventType == 'achievement') {
      leading = CircleAvatar(
        radius: 22,
        backgroundColor: tokens.surfaceAlt,
        child: hidden
            ? Icon(Icons.lock_outline_rounded, color: tokens.inkFaint)
            : Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  ((payload['achievement_badge_path'] ?? '') as String)
                          .isNotEmpty
                      ? payload['achievement_badge_path'] as String
                      : 'lib/assets/badges/first_sip.png',
                  errorBuilder: (_, _, _) =>
                      Image.asset('lib/assets/badges/first_sip.png'),
                ),
              ),
      );
    } else {
      final mark = BrandMark(
        name: brandLabel,
        slug: slug.isEmpty ? brandLabel : slug,
        iconPath: brand?.iconPath,
        size: 44,
      );
      if (variant == FeedCardVariant.friends) {
        leading = SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(right: 0, top: 0, child: mark),
              Positioned(
                left: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.surface, width: 2),
                  ),
                  child: ThumbPic(
                    path: user.profileImagePath,
                    size: 20,
                    initials: initialFrom(
                      firstName: user.firstName,
                      displayName: user.displayName,
                      username: user.username,
                    ),
                    onTap: openProfile,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        leading = mark;
      }
    }

    final currentId = context.select<UserState, String>((s) => s.current.id);
    final inDex =
        slug.isNotEmpty &&
        context.select<ShopState, bool>(
          (s) => s.getShopByBrand(currentId, slug) != null,
        );
    final showDexChip =
        variant == FeedCardVariant.friends &&
        event.eventType == 'shop_add' &&
        slug.isNotEmpty &&
        brand != null;

    return InkWell(
      onTap: event.eventType == 'achievement' ? openAchievement : openBrand,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: BobaSpace.x3),
                Expanded(child: title),
                if (event.eventType != 'achievement' &&
                    rating != null &&
                    rating > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: BobaSpace.x2),
                    child: RatingText(
                      value: rating,
                      size: RatingTextSize.small,
                    ),
                  ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: BobaSpace.x2),
              Text(
                notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (images.isNotEmpty) ...[
              const SizedBox(height: BobaSpace.x2),
              HorizontalPhotoPreview(
                shopMediaList: images.map((img) {
                  final map = img is Map
                      ? Map<String, dynamic>.from(img)
                      : <String, dynamic>{};
                  return ShopMedia.galleryViewMedia(
                    imagePath: (map['path'] ?? '').toString(),
                    comment: (map['comment'] ?? '').toString(),
                  );
                }).toList(),
                height: 64,
                width: 64,
                maxPreview: 4,
                showUserInfo: false,
              ),
            ],
            const SizedBox(height: BobaSpace.x2),
            Row(
              children: [
                Text(
                  _timeAgo(event.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: tokens.inkMuted),
                ),
                const Spacer(),
                if (showDexChip)
                  BobaChip(
                    label: inDex ? 'In your dex ✓' : 'Add to dex',
                    selected: inDex,
                    onTap: inDex ? null : openBrand,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _titleSpans({
    required FeedCardVariant variant,
    required String type,
    required String actor,
    required String brandLabel,
    required String drinkName,
    required String shopName,
    required String achievementName,
    required bool hidden,
    required TextStyle? muted,
    required TextStyle? bold,
  }) {
    final profile = variant == FeedCardVariant.userProfile;
    final who = profile
        ? <InlineSpan>[]
        : [
            TextSpan(text: actor, style: bold),
            TextSpan(text: ' ', style: muted),
          ];

    switch (type) {
      case 'shop_add':
        return [
          ...who,
          TextSpan(text: 'collected ', style: muted),
          TextSpan(text: brandLabel, style: bold),
        ];
      case 'drink_add':
        if (drinkName.isNotEmpty) {
          return [
            ...who,
            TextSpan(text: 'logged ', style: muted),
            TextSpan(text: drinkName, style: bold),
            TextSpan(text: ' at $shopName', style: muted),
          ];
        }
        return [
          ...who,
          TextSpan(text: 'logged a drink at ', style: muted),
          TextSpan(text: shopName, style: bold),
        ];
      case 'achievement':
        return [
          ...who,
          TextSpan(text: 'unlocked ', style: muted),
          TextSpan(
            text: hidden ? 'a hidden badge' : achievementName,
            style: bold,
          ),
        ];
      default:
        return [...who, TextSpan(text: type, style: muted)];
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt.toLocal());
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class FeedEventRowSkeleton extends StatelessWidget {
  const FeedEventRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: BobaCard(
        child: Row(
          children: [
            SkeletonCircle(size: 44),
            SizedBox(width: 12),
            Expanded(child: SkeletonText(lines: 2)),
          ],
        ),
      ),
    );
  }
}

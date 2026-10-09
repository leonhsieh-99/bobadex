import 'package:bobadex/models/achievement.dart';
import 'package:bobadex/ui/components/boba_card.dart';
import 'package:bobadex/ui/components/stat_chip.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';

enum CollectorCardVariant { full, compact }

class CollectorCard extends StatelessWidget {
  const CollectorCard({
    super.key,
    required this.displayName,
    required this.username,
    this.variant = CollectorCardVariant.full,
    this.bio,
    this.profileImagePath,
    this.createdAt,
    this.brandCount = 0,
    this.drinkCount = 0,
    this.badgeCount = 0,
    this.badges = const [],
    this.favorite,
    this.onBadgeTap,
    this.onFavoriteTap,
    this.onEdit,
    this.trailing,
    this.caption,
    this.onTap,
  });

  final CollectorCardVariant variant;
  final String displayName;
  final String username;
  final String? bio;
  final String? profileImagePath;
  final DateTime? createdAt;
  final int brandCount;
  final int drinkCount;
  final int badgeCount;
  final List<Achievement> badges;
  final Widget? favorite;
  final ValueChanged<Achievement>? onBadgeTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onEdit;
  final Widget? trailing;
  final String? caption;
  final VoidCallback? onTap;

  static const _months = [
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

  @override
  Widget build(BuildContext context) {
    if (variant == CollectorCardVariant.compact) {
      return _compact(context);
    }
    return _full(context);
  }

  Widget _compact(BuildContext context) {
    final tokens = context.boba;
    return ListTile(
      onTap: onTap,
      leading: ThumbPic(
        path: profileImagePath,
        initials: displayName,
        size: 40,
      ),
      title: Text(displayName),
      subtitle: Text(
        caption ?? '@$username · $brandCount brands',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: tokens.inkMuted),
      ),
      trailing: trailing,
    );
  }

  Widget _full(BuildContext context) {
    final tokens = context.boba;
    final bioText = bio?.trim();
    final since = createdAt == null
        ? null
        : 'Collector since ${_months[createdAt!.month - 1]} ${createdAt!.year}';

    return BobaCard(
      padding: EdgeInsets.zero,
      borderRadius: BobaRadius.xl,
      child: Column(
        children: [
          SizedBox(
            height: 72,
            width: double.infinity,
            child: CustomPaint(
              painter: _BandPainter(
                color: tokens.accent.withValues(alpha: 0.1),
              ),
              child: ColoredBox(
                color: tokens.accentSoft,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BobaSpace.x4,
                    ),
                    child: Text(
                      'BOBADEX',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.accentInk,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -44),
            child: Column(
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: tokens.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ThumbPic(
                          path: profileImagePath,
                          initials: displayName,
                          size: 88,
                        ),
                      ),
                      if (onEdit != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: tokens.accent,
                            shape: const CircleBorder(),
                            child: Tooltip(
                              message: 'Edit profile',
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onEdit,
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Icon(
                                    Icons.edit_rounded,
                                    size: 15,
                                    color: tokens.onAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: BobaSpace.x3),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  '@$username',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.inkMuted),
                ),
                if (bioText != null && bioText.isNotEmpty) ...[
                  const SizedBox(height: BobaSpace.x2),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BobaSpace.x4,
                    ),
                    child: Text(
                      bioText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: BobaSpace.x4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x4),
                  child: StatTrio(
                    children: [
                      StatChip(
                        icon: const Icon(Icons.storefront_rounded),
                        value: brandCount,
                        label: 'Brands',
                      ),
                      StatChip(
                        icon: const Icon(Icons.local_drink_rounded),
                        value: drinkCount,
                        label: 'Drinks',
                      ),
                      StatChip(
                        icon: const Icon(Icons.military_tech_rounded),
                        value: badgeCount,
                        label: 'Badges',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: BobaSpace.x4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: BobaSpace.x3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: _BadgeSlot(
                            badge: i < badges.length ? badges[i] : null,
                            onTap: i < badges.length && onBadgeTap != null
                                ? () => onBadgeTap!(badges[i])
                                : onBadgeTap != null && badges.isEmpty
                                ? () => onBadgeTap!(
                                    Achievement(
                                      id: '',
                                      name: '',
                                      description: '',
                                      iconPath: null,
                                      displayOrder: 0,
                                      dependsOn: const {},
                                    ),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
                if (favorite != null) ...[
                  const SizedBox(height: BobaSpace.x4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BobaSpace.x4,
                    ),
                    child: BobaCard(
                      variant: BobaCardVariant.inset,
                      padding: EdgeInsets.zero,
                      onTap: onFavoriteTap,
                      child: favorite!,
                    ),
                  ),
                ],
                const SizedBox(height: BobaSpace.x4),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: tokens.accentSoft,
            padding: const EdgeInsets.fromLTRB(
              BobaSpace.x4,
              BobaSpace.x2,
              BobaSpace.x4,
              BobaSpace.x3,
            ),
            child: since == null
                ? const SizedBox(height: 4)
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      since,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: tokens.accentInk),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BadgeSlot extends StatelessWidget {
  const _BadgeSlot({this.badge, this.onTap});

  final Achievement? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final filled = badge != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? tokens.surfaceAlt : null,
              border: filled
                  ? null
                  : Border.all(
                      color: tokens.outline,
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
            ),
            child: filled
                ? Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      (badge!.iconPath != null && badge!.iconPath!.isNotEmpty)
                          ? badge!.iconPath!
                          : 'lib/assets/badges/first_sip.png',
                    ),
                  )
                : Icon(Icons.shield_outlined, color: tokens.inkFaint),
          ),
          const SizedBox(height: 4),
          Text(
            filled ? badge!.name : '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    const cols = 8;
    const rows = 3;
    final w = (size.width - 18) / cols;
    final h = (size.height - 12) / rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(6 + c * w, 4 + r * h, w - 4, h - 4),
            const Radius.circular(4),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BandPainter oldDelegate) =>
      oldDelegate.color != color;
}

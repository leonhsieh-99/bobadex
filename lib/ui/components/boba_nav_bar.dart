import 'package:bobadex/config/feature_flags.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class BobaNavDestination {
  const BobaNavDestination({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int badgeCount;
}

class BobaNavBar extends StatelessWidget {
  static const double barHeight = 64;
  static const double plusSize = 52;
  static const double plusGap = 56;
  static const double extent = 72;

  /// Space from the bottom of the screen to the bar. The home-indicator
  /// inset already clears the gesture area, so only a small gap is added.
  static double bottomOffset(BuildContext context) {
    return BobaSpace.x2 + MediaQuery.paddingOf(context).bottom;
  }

  static double clearance(BuildContext context) {
    return extent + bottomOffset(context);
  }

  const BobaNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddPressed,
    this.friendsBadgeCount = 0,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddPressed;
  final int friendsBadgeCount;

  List<BobaNavDestination> get _destinations => [
    const BobaNavDestination(icon: Icons.grid_view_rounded, label: 'Dex'),
    if (FeatureFlags.collection)
      const BobaNavDestination(icon: Icons.menu_book_rounded, label: 'Collect'),
    BobaNavDestination(
      icon: Icons.group_rounded,
      label: 'Friends',
      badgeCount: friendsBadgeCount,
    ),
    const BobaNavDestination(icon: Icons.person_rounded, label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final destinations = _destinations;
    final insertAt = (destinations.length + 1) ~/ 2;

    return SizedBox(
      height: extent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barW = constraints.maxWidth;
          final slotW = (barW - plusGap) / destinations.length;
          final selected = selectedIndex.clamp(0, destinations.length - 1);
          final bubbleLeft =
              selected * slotW + (selected >= insertAt ? plusGap : 0);
          final plusLeft = insertAt * slotW + plusGap / 2 - plusSize / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(BobaRadius.pill),
                    border: Border.all(
                      color: tokens.outline.withValues(alpha: 0.7),
                      width: BobaStroke.hairline,
                    ),
                    boxShadow: [BobaShadow.floating(tokens)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(BobaRadius.pill),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: BobaMotion.normal,
                          curve: Curves.easeOutCubic,
                          left: bubbleLeft + 6,
                          top: 6,
                          bottom: 6,
                          width: slotW - 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tokens.accentSoft,
                              borderRadius: BorderRadius.circular(
                                BobaRadius.pill,
                              ),
                              border: Border.all(
                                color: tokens.accent.withValues(alpha: 0.28),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < destinations.length; i++) ...[
                              if (i == insertAt) const SizedBox(width: plusGap),
                              SizedBox(
                                width: slotW,
                                child: _NavSlot(
                                  destination: destinations[i],
                                  selected: selectedIndex == i,
                                  onTap: () => onDestinationSelected(i),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: plusLeft,
                child: Material(
                  color: tokens.accent,
                  elevation: 2,
                  shadowColor: tokens.shadow,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onAddPressed,
                    child: SizedBox(
                      width: plusSize,
                      height: plusSize,
                      child: Icon(
                        Icons.add_rounded,
                        color: tokens.onAccent,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final BobaNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final color = selected ? tokens.accentInk : tokens.inkMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BobaRadius.pill),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: destination.badgeCount > 0,
            backgroundColor: tokens.danger,
            label: Text(
              '${destination.badgeCount}',
              style: context.bobaText.badge,
            ),
            child: Icon(destination.icon, size: 22, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            destination.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

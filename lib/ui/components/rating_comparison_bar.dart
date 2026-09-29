import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/widgets/thumb_pic.dart';
import 'package:flutter/material.dart';

class RatingComparisonMarker {
  const RatingComparisonMarker({
    required this.id,
    required this.rating,
    this.path,
    this.initials,
    this.isYou = false,
    this.onTap,
  });

  final String id;
  final double rating;
  final String? path;
  final String? initials;
  final bool isYou;
  final VoidCallback? onTap;
}

class RatingComparisonBar extends StatelessWidget {
  const RatingComparisonBar({super.key, required this.markers});

  final List<RatingComparisonMarker> markers;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    if (markers.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const avatar = 24.0;
              final usable = constraints.maxWidth - avatar;
              final buckets = <int, List<RatingComparisonMarker>>{};
              for (final m in markers) {
                final key = (m.rating * 2).round();
                buckets.putIfAbsent(key, () => []).add(m);
              }
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: avatar / 2,
                    right: avatar / 2,
                    bottom: 10,
                    child: Container(height: 2, color: tokens.outline),
                  ),
                  for (final entry in buckets.entries)
                    for (var i = 0; i < entry.value.length && i < 2; i++)
                      Positioned(
                        left:
                            ((entry.value[i].rating.clamp(1, 5) - 1) / 4) *
                            usable,
                        bottom: i == 0 ? 0 : 22,
                        child: GestureDetector(
                          onTap: entry.value[i].onTap,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: entry.value[i].isYou
                                    ? tokens.accent
                                    : tokens.surface,
                                width: 2,
                              ),
                            ),
                            child: ThumbPic(
                              path: entry.value[i].path,
                              size: avatar - 4,
                              initials: entry.value[i].initials,
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final n in [1, 2, 3, 4, 5])
              Text(
                '$n',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: tokens.inkMuted),
              ),
          ],
        ),
      ],
    );
  }
}

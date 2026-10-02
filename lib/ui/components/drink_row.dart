import 'package:bobadex/models/drink.dart';
import 'package:bobadex/ui/components/rating_text.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DrinkRow extends StatelessWidget {
  const DrinkRow({
    super.key,
    required this.drink,
    required this.expanded,
    this.isPinned = false,
    this.isOwner = false,
    this.onToggleExpand,
    this.onFavorite,
    this.onMenuSelected,
  });

  final Drink drink;
  final bool expanded;
  final bool isPinned;
  final bool isOwner;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onFavorite;
  final ValueChanged<String>? onMenuSelected;

  bool get _hasNotes => drink.notes != null && drink.notes!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final notes = drink.notes?.trim() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _hasNotes ? onToggleExpand : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 0, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: RatingText(
                    value: drink.rating,
                    size: RatingTextSize.small,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPinned) ...[
                          Icon(
                            Icons.bookmark_rounded,
                            size: 14,
                            color: tokens.heart,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            drink.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    if (_hasNotes) ...[
                      const SizedBox(height: 4),
                      Text(
                        notes,
                        maxLines: expanded ? null : 2,
                        overflow: expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.inkMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: isOwner ? onFavorite : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
                      child: SvgPicture.asset(
                        drink.isFavorite
                            ? 'lib/assets/icons/heart.svg'
                            : 'lib/assets/icons/heart_outlined.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: tokens.inkMuted,
                      ),
                      onSelected: onMenuSelected,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(isPinned ? 'Unpin' : 'Pin'),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove'),
                        ),
                      ],
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

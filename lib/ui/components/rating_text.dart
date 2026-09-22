import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

enum RatingTextSize { small, medium, large }

class RatingText extends StatelessWidget {
  const RatingText({
    super.key,
    required this.value,
    this.size = RatingTextSize.medium,
  });

  final double? value;
  final RatingTextSize size;

  double get _fontSize => switch (size) {
    RatingTextSize.small => 13,
    RatingTextSize.medium => 16,
    RatingTextSize.large => 22,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final label = value == null || value == 0 ? '—' : value!.toStringAsFixed(1);
    return Semantics(
      label: value == null || value == 0 ? 'Unrated' : '$label out of 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.bobaText.numeral(fontSize: _fontSize)),
            const SizedBox(width: 3),
            Icon(
              Icons.star_rounded,
              size: _fontSize,
              color: tokens.star,
              shadows: tokens.starOutline.a == 0
                  ? null
                  : [Shadow(color: tokens.starOutline, blurRadius: 0)],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:bobadex/config/constants.dart';
import 'package:bobadex/widgets/outlined_star.dart';
import 'package:flutter/material.dart';

class RatingPicker extends StatelessWidget {
  final double rating;
  final void Function(double)? onChanged;
  final double? size;

  const RatingPicker({
    super.key,
    this.rating = 3.0,
    this.onChanged,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 50.0;
    final color = Constants.starColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final starCount = 5;
        final spacing = 12.0;
        final totalSpacing = spacing * (starCount - 1);
        final starSize = (width - totalSpacing) / starCount;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max,
          children: List.generate(starCount, (index) {
            double current = index + 1.0;
            final bool filled = rating >= current;
            final bool half = rating >= current - 0.5 && rating < current;

            final star = SizedBox(
              width: starSize,
              height: starSize,
              child: OutlinedStar(
                size: starSize,
                filled: filled,
                half: half,
                fillColor: color,
                borderColor: Colors.black,
              ),
            );

            if (onChanged == null) return star;

            return Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (details) {
                    final localX = details.localPosition.dx;
                    final width = iconSize;
                    final isHalf = localX < width / 2;
                    double value = isHalf ? current - 0.5 : current;

                    if (value == 0.5) {
                      value = 1.0;
                    }

                    onChanged!(value);
                  },
                  onTapDown: (details) {
                    final localX = details.localPosition.dx;
                    final width = iconSize;
                    final isHalf = localX < width / 2;
                    double value = isHalf ? current - 0.5 : current;
                    if (value == 0.5) value = 1.0;
                    value = value.clamp(1.0, 5.0);
                    onChanged!(value);
                  },
                  child: star,
                ),
                if (index != starCount - 1)
                  SizedBox(width: spacing),
              ],
            );
          }),
        );
      }
    );
  }
}

import 'package:bobadex/config/constants.dart';
import 'package:bobadex/widgets/outlined_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final color = Constants.starColor;
    final starCount = 5;
    final spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final totalSpacing = spacing * (starCount - 1);
        final starSize = ((width - totalSpacing) / starCount).clamp(0, double.infinity);
        final clampedStarSize = size == null ? starSize : starSize.clamp(0, size!);
        final trackWidth = clampedStarSize * starCount + totalSpacing;

        double _valueFromDx(double dx) {
          // local x within the track [0, trackWidth]
          final x = dx.clamp(0.0, trackWidth);
          for (int i = 0; i < starCount; i++) {
            final startX = i * (clampedStarSize + spacing);
            final endX = startX + clampedStarSize;
            if (x >= startX && x <= endX) {
              final within = x - startX;
              final isHalf = within < clampedStarSize / 2;
              double v = (i + 1).toDouble();
              if (isHalf) v -= 0.5;
              if (v < 1.0) v = 1.0;
              return v.clamp(0.5, starCount.toDouble());
            }
          }
          // If in the gaps or past the ends, snap to nearest
          final idx = (x / (clampedStarSize + spacing)).floor();
          final v = (idx + 1).toDouble();
          return v.clamp(1.0, starCount.toDouble());
        }

        void _update(Offset localPos) {
          if (onChanged == null) return;
          final newValue = _valueFromDx(localPos.dx);
          if (newValue != rating) {
            HapticFeedback.selectionClick();
            onChanged!(newValue);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _update(d.localPosition),
          onPanStart: (d) => _update(d.localPosition),
          onPanUpdate: (d) => _update(d.localPosition),
          child: SizedBox(
            width: trackWidth,
            height: clampedStarSize.toDouble(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(starCount, (index) {
                final current = index + 1.0;
                final filled = rating >= current;
                final half = rating >= current - 0.5 && rating < current;
                return Padding(
                  padding: EdgeInsets.only(right: index == starCount - 1 ? 0 : spacing),
                  child: SizedBox(
                    width: clampedStarSize.toDouble(),
                    height: clampedStarSize.toDouble(),
                    child: OutlinedStar(
                      size: clampedStarSize.toDouble(),
                      filled: filled,
                      half: half,
                      fillColor: color,
                      borderColor: Colors.black,
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      }
    );
  }
}

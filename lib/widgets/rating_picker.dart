import 'package:bobadex/config/constants.dart';
import 'package:flutter/material.dart';

class RatingPicker extends StatelessWidget {
  final double rating;
  final void Function(double)? onChanged;
  final double? size;

  const RatingPicker({
    super.key,
    this.rating = 0.0,
    this.onChanged,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 50.0;
    final color = Constants.starColor;

    return Row(
      children: List.generate(5, (index) {
        double current = index + 1.0;
        IconData iconData;

        Widget outlinedStar(IconData filledIcon, double size, Color fillColor, {Color outlineColor = Colors.black}) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: size + 4,
                color: outlineColor,
              ),
              // Filled Star (or half)
              Icon(
                filledIcon,
                size: size,
                color: fillColor,
              ),
            ],
          );
        }

        if (rating >= current) {
          iconData = Icons.star;
        } else if (rating >= current - 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }

        Widget icon = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: outlinedStar(iconData, iconSize, color),
        );


        if (onChanged != null) {
          return GestureDetector(
            onPanDown: (details) {
              final localX = details.localPosition.dx;
              final width = iconSize;
              final isHalf = localX < width / 2;

              onChanged!(isHalf ? current - 0.5 : current);
            },
            child: icon,
          );
        }

        return icon;
      }),
    );
  }
}

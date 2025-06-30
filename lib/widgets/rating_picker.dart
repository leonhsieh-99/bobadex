import 'package:bobadex/config/constants.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RatingPicker extends StatelessWidget {
  final double rating;
  final void Function(double)? onChanged;

  const RatingPicker({
    super.key,
    required this.rating,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserState>().user;
    final iconSize = 50.0;
    final color = Constants.getThemeColor(user.themeSlug).shade700;

    return Row(
      children: List.generate(5, (index) {
        double current = index + 1.0;
        IconData iconData;

        if (rating >= current) {
          iconData = Icons.star;
        } else if (rating >= current - 0.5) {
          iconData = Icons.star_half;
        } else {
          iconData = Icons.star_border;
        }

        Widget icon = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            iconData,
            size: iconSize,
            color: color,
          ),
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

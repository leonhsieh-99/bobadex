import 'package:flutter/material.dart';

class RatingPicker extends StatelessWidget{
  final double rating;
  final void Function(double) onChanged;

  const RatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = 50.0;
    return Row(
      children: List.generate(5, (index) {
        double current = index + 1.0;
        IconData icon;

        if (rating >= current) {
          icon = Icons.circle;
        } else if (rating >= current - 0.5) {
          icon = Icons.adjust;
        } else {
          icon = Icons.circle_outlined;
        }

        return GestureDetector(
          onPanDown: (details) {
            final localX = details.localPosition.dx;
            final width = iconSize; // icon size
            final isHalf = localX < width / 2;

            onChanged(isHalf ? current - 0.5 : current);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(icon, size: iconSize, color: Colors.brown),
          ),
        );
      }),
    );
  }
}

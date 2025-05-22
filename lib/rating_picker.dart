import 'package:flutter/material.dart';

class RatingPicker extends StatelessWidget{
  final double rating;
  final void Function(double) onChanged;
  final IconData filledIcon;
  final IconData halfIcon;
  final IconData emptyIcon;

  const RatingPicker({
    super.key,
    required this.rating,
    required this.onChanged,
    required this.filledIcon,
    required this.halfIcon,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        double current = index + 1.0;
        IconData icon;

        if (rating >= current) {
          icon = filledIcon;
        } else if (rating >= current - 0.5) {
          icon = halfIcon;
        } else {
          icon = emptyIcon;
        }

        return GestureDetector(
          onTap: () => onChanged(current),
          onLongPress: () => onChanged(current - 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class NumberRating extends StatelessWidget {
  final String rating;
  final double size;

  const NumberRating({super.key, required this.rating, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          rating,
          style: TextStyle(
            fontFamily: 'NotoSerif',
            fontWeight: FontWeight.w600,
            fontSize: size,
          ),
        ),
        SizedBox(width: 4),
        SvgPicture.asset(
          'lib/assets/icons/star.svg',
          width: size,
          height: size,
        )
      ],
    );
  }
}
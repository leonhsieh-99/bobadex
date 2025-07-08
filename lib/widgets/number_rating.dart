import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
          style: GoogleFonts.notoSerif(
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
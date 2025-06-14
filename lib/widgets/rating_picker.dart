import 'package:bobadex/config/constants.dart';
import 'package:bobadex/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

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
    final user = context.watch<UserState>().user;
    final iconSize = 50.0;
    return Row(
      children: List.generate(5, (index) {
        double current = index + 1.0;
        String asset;

        if (rating >= current) {
          asset = 'lib/assets/icons/tapioca_pearls/pearl_full.svg';
        } else if (rating >= current - 0.5) {
          asset = 'lib/assets/icons/tapioca_pearls/pearl_half.svg';
        } else {
          asset = 'lib/assets/icons/tapioca_pearls/pearl_outline.svg';
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
            child: SvgPicture.asset(
              asset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(Constants.getThemeColor(user.themeSlug).shade700, BlendMode.srcIn),
            )
          ),
        );
      }),
    );
  }
}

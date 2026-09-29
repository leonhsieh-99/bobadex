import 'package:bobadex/collection/collection_models.dart';
import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:flutter/material.dart';

class RegionSeal extends StatelessWidget {
  const RegionSeal({
    super.key,
    required this.name,
    this.size = 48,
    this.complete = false,
  });

  final String name;
  final double size;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final ring = complete ? tokens.accent : tokens.ink;
    final fill = complete ? tokens.accent : tokens.surfaceAlt;
    final ink = complete ? tokens.onAccent : tokens.ink;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: ring, width: 1.5),
      ),
      child: Text(
        countyAbbreviation(name),
        style: context.bobaText
            .numeral(fontSize: size * 0.28)
            .copyWith(color: ink),
      ),
    );
  }
}

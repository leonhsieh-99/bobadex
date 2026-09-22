import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class DexHeader extends StatelessWidget {
  const DexHeader({
    super.key,
    required this.title,
    required this.brandCount,
    required this.drinkCount,
  });

  final String title;
  final int brandCount;
  final int drinkCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BobaSpace.x4,
        BobaSpace.x5,
        BobaSpace.x4,
        BobaSpace.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: BobaSpace.x1),
          Text(
            '$brandCount brands · $drinkCount drinks',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.boba.inkMuted),
          ),
        ],
      ),
    );
  }
}

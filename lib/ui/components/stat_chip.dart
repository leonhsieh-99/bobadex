import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(BobaRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BobaSpace.x3,
          vertical: BobaSpace.x2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme.merge(
              data: IconThemeData(color: tokens.accentInk, size: 18),
              child: icon,
            ),
            const SizedBox(width: BobaSpace.x2),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$value', style: context.bobaText.numeral(fontSize: 18)),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatTrio extends StatelessWidget {
  const StatTrio({super.key, required this.children})
    : assert(children.length == 3);

  final List<StatChip> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: BobaSpace.x2),
        ],
      ],
    );
  }
}

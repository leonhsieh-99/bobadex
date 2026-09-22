import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class BobaProgressBar extends StatelessWidget {
  const BobaProgressBar({
    super.key,
    required this.value,
    this.label,
    this.semanticsLabel,
    this.height = 8,
  });

  final double value;
  final String? label;
  final String? semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final progress = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticsLabel ?? label,
      value: '${(progress * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(
              label!,
              textAlign: TextAlign.end,
              style: context.bobaText.numeral(fontSize: 13),
            ),
            const SizedBox(height: BobaSpace.x1),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(BobaRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: height,
              color: tokens.accent,
              backgroundColor: tokens.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }
}

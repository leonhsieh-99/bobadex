import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class BobaSheet extends StatelessWidget {
  const BobaSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BobaSpace.x4),
    this.showGrabber = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BobaRadius.xl),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showGrabber) ...[
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.outline,
                  borderRadius: BorderRadius.circular(BobaRadius.pill),
                ),
              ),
              const SizedBox(height: BobaSpace.x3),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

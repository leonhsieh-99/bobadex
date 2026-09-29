import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class BobaSheet extends StatelessWidget {
  const BobaSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BobaSpace.x4),
    this.showGrabber = false,
    this.expand = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final body = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showGrabber) ...[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.outline,
                  borderRadius: BorderRadius.circular(BobaRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: BobaSpace.x3),
          ],
          expand ? Expanded(child: child) : child,
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BobaRadius.xl),
        ),
      ),
      child: expand ? SizedBox.expand(child: body) : body,
    );
  }
}

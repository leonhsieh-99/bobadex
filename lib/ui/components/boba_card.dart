import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

enum BobaCardVariant { flat, floating, inset }

class BobaCard extends StatefulWidget {
  const BobaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(BobaSpace.x4),
    this.variant = BobaCardVariant.flat,
    this.onTap,
    this.accentSpine,
    this.borderRadius = BobaRadius.lg,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BobaCardVariant variant;
  final VoidCallback? onTap;
  final Color? accentSpine;
  final double borderRadius;
  final Clip clipBehavior;

  @override
  State<BobaCard> createState() => _BobaCardState();
}

class _BobaCardState extends State<BobaCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || value == _pressed) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final inset = widget.variant == BobaCardVariant.inset;
    final floating = widget.variant == BobaCardVariant.floating;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: BobaMotion.press,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: inset ? tokens.surfaceAlt : tokens.surface,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: inset
              ? null
              : Border.all(color: tokens.outline, width: BobaStroke.card),
          boxShadow: floating ? [BobaShadow.floating(tokens)] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          clipBehavior: widget.clipBehavior,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Stack(
                children: [
                  if (widget.accentSpine != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: ColoredBox(
                        color: widget.accentSpine!,
                        child: const SizedBox(width: 3),
                      ),
                    ),
                  Padding(padding: widget.padding, child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

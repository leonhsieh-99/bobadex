import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = BobaRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.boba;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      return _box(tokens.surfaceAlt);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => _box(
        Color.lerp(tokens.surfaceAlt, tokens.outline, _controller.value)!,
      ),
    );
  }

  Widget _box(Color color) => SizedBox(
    width: widget.width,
    height: widget.height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SkeletonBox(width: size, height: size, radius: size),
    );
  }
}

class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 2,
    this.lineHeight = 12,
    this.spacing = BobaSpace.x2,
  });

  final int lines;
  final double lineHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++) ...[
          FractionallySizedBox(
            widthFactor: i == lines - 1 ? 0.68 : 1,
            child: SkeletonBox(height: lineHeight),
          ),
          if (i != lines - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

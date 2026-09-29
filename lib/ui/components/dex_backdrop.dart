import 'package:bobadex/ui/theme/boba_context.dart';
import 'package:bobadex/ui/theme/boba_tokens.dart';
import 'package:flutter/material.dart';

class DexBackdrop extends StatelessWidget {
  const DexBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DexBackdropPainter(
        outline: context.boba.outline.withValues(alpha: 0.55),
        fill: context.boba.accent.withValues(alpha: 0.12),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DexBackdropPainter extends CustomPainter {
  _DexBackdropPainter({required this.outline, required this.fill});

  final Color outline;
  final Color fill;

  static const _filled = {(0, 1), (1, 2), (2, 0)};

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 4;
    const rows = 3;
    const gap = 10.0;
    final tileW = (size.width - gap * (cols + 1)) / cols;
    final tileH = (size.height - gap * (rows + 1)) / rows;
    final radius = Radius.circular(BobaRadius.md);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = BobaStroke.card
      ..color = outline;
    final fillPaint = Paint()..color = fill;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            gap + c * (tileW + gap),
            gap + r * (tileH + gap),
            tileW,
            tileH,
          ),
          radius,
        );
        if (_filled.contains((r, c))) {
          canvas.drawRRect(rect, fillPaint);
        }
        canvas.drawRRect(rect, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DexBackdropPainter oldDelegate) {
    return oldDelegate.outline != outline || oldDelegate.fill != fill;
  }
}

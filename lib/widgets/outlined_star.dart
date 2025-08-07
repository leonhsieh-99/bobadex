import 'dart:math' as math;
import 'package:flutter/material.dart';

class OutlinedStar extends StatelessWidget {
  final double size;
  final bool filled;
  final bool half;
  final Color fillColor;
  final Color borderColor;

  const OutlinedStar({
    super.key,
    required this.size,
    this.filled = false,
    this.half = false,
    this.fillColor = Colors.amber,
    this.borderColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarPainter(
          filled: filled,
          half: half,
          fillColor: fillColor,
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final bool filled;
  final bool half;
  final Color fillColor;
  final Color borderColor;

  _StarPainter({
    required this.filled,
    required this.half,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path starPath = _starPath(size);

    // Draw half-filled star
    if (half) {
      // Draw filled left half
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
      canvas.drawPath(
        starPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
      // Draw outline on top
      canvas.drawPath(
        starPath,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      return;
    }

    // Draw fully filled star
    if (filled) {
      canvas.drawPath(
        starPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }
    // Draw outline
    canvas.drawPath(
      starPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  Path _starPath(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double outerRadius = w / 2;
    final double innerRadius = outerRadius * 0.4;
    final Path path = Path();

    for (int i = 0; i < 5; i++) {
      double angle = math.pi / 2 + i * 2 * math.pi / 5;
      double x = cx + outerRadius * math.cos(angle);
      double y = cy - outerRadius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      angle += math.pi / 5;
      x = cx + innerRadius * math.cos(angle);
      y = cy - innerRadius * math.sin(angle);
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

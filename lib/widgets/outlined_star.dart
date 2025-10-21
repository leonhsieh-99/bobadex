import 'dart:math' as math;
import 'package:flutter/material.dart';

class OutlinedStar extends StatelessWidget {
  final double size;
  final bool filled;
  final bool half;
  final Color fillColor;
  final Color borderColor;
  final double cornerRadius;
  final double innerRadiusFactor;

  const OutlinedStar({
    super.key,
    required this.size,
    this.filled = false,
    this.half = false,
    this.fillColor = Colors.amber,
    this.borderColor = Colors.black,
    this.cornerRadius = 0,
    this.innerRadiusFactor = 0.4,
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
          cornerRadius: cornerRadius <= 0 ? size * 0.1 : cornerRadius,
          innerRadiusFactor: innerRadiusFactor,
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
  final double cornerRadius;
  final double innerRadiusFactor;

  _StarPainter({
    required this.filled,
    required this.half,
    required this.fillColor,
    required this.borderColor,
    required this.cornerRadius,
    required this.innerRadiusFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path starPath = _roundedStarPath(size, cornerRadius, innerRadiusFactor);

    // Half-filled star: clip to star, then clip to left half, then fill
    if (half) {
      canvas.save();
      canvas.clipPath(starPath);
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = fillColor..style = PaintingStyle.fill,
      );
      canvas.restore();

      // Outline on top
      canvas.drawPath(
        starPath,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
      return;
    }

    // Full fill
    if (filled) {
      canvas.drawPath(
        starPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }

    // Outline
    canvas.drawPath(
      starPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round // smooth joins
        ..isAntiAlias = true,
    );
  }

  Path _roundedStarPath(Size size, double r, double innerFactor) {
    final double w = size.width;
    final double h = size.height;
    final Offset c = Offset(w / 2, h / 2);
    final double outerR = w / 2; // assumes square box
    final double innerR = outerR * innerFactor;

    final List<Offset> pts = [];
    for (int i = 0; i < 10; i++) {
      final bool isOuter = i.isEven;
      final double radius = isOuter ? outerR : innerR;
      // Start at -90° (top) and step 36° each point (360/10)
      final double angle = -math.pi / 2 + i * (2 * math.pi / 10);
      pts.add(Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      ));
    }

    Path path = Path();
    for (int i = 0; i < pts.length; i++) {
      final Offset prev = pts[(i - 1 + pts.length) % pts.length];
      final Offset curr = pts[i];
      final Offset next = pts[(i + 1) % pts.length];

      final Offset vIn = (curr - prev);
      final Offset vOut = (curr - next);

      final double lenIn = vIn.distance;
      final double lenOut = vOut.distance;

      final double cut = math.min(r, math.min(lenIn, lenOut) * 0.45);

      final Offset p1 = curr - (vIn / lenIn) * cut; // approach point
      final Offset p2 = curr - (vOut / lenOut) * cut; // exit point

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) {
    return old.filled != filled ||
        old.half != half ||
        old.fillColor != fillColor ||
        old.borderColor != borderColor ||
        old.cornerRadius != cornerRadius ||
        old.innerRadiusFactor != innerRadiusFactor;
  }
}

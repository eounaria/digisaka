import 'package:flutter/material.dart';

/// Dashed rounded border (used for the "Unvalidated" group card).
/// Use it as a foregroundPainter so the border draws on top of the card.
class DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;

  const DashedRRectPainter({
    this.color = const Color(0xFFB5BDB3),
    this.radius = 18,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    const double dash = 5;
    const double gap = 4;
    final Path dashed = Path();

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashed.addPath(metric.extractPath(distance, distance + dash), Offset.zero);
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'dart:math' as math;

import 'package:flutter/material.dart';

class LineTrendChart extends StatelessWidget {
  const LineTrendChart({
    super.key,
    required this.points,
    this.height = 110,
    this.color = const Color(0xFF0E7C86),
  });

  final List<double> points;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Not enough data yet')),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _LineTrendPainter(points: points, strokeColor: color),
      ),
    );
  }
}

class _LineTrendPainter extends CustomPainter {
  _LineTrendPainter({required this.points, required this.strokeColor});

  final List<double> points;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = points.reduce(math.max);
    final range = maxValue < 0.001 ? 1.0 : maxValue;

    final n = points.length;
    final slotWidth = size.width / n;
    final barWidth = slotWidth * 0.55;
    final gap = slotWidth * 0.45;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1A283445)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bars
    for (var i = 0; i < n; i++) {
      final normalized = points[i] / range;
      final barHeight = math.max(normalized * (size.height - 4), 4.0);
      final x = i * slotWidth + gap / 2;
      final y = size.height - barHeight;

      final isLast = i == n - 1;
      final barColor = isLast
          ? strokeColor
          : strokeColor.withValues(alpha: 0.55);

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [barColor, barColor.withValues(alpha: 0.35)],
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        ),
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineTrendPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor;
  }
}

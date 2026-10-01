import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:upgrade/resources.dart';

/// Shared native typography for the onboarding pages.
class ObTitle extends StatelessWidget {
  final String text;
  final double size;
  const ObTitle(this.text, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1.3,
          color: AppColor.darkGreenColor,
        ),
      );
}

class ObBody extends StatelessWidget {
  final String text;
  const ObBody(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColor.textSecondary.withOpacity(0.9),
        ),
      );
}

/// Empty "missing piece" slot (dashed outline) for page 1.
class DashedSlot extends StatelessWidget {
  const DashedSlot({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashedPainter());
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(24),
    );
    canvas.drawRRect(
        rrect, Paint()..color = Colors.white.withOpacity(0.35));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColor.textSecondary.withOpacity(0.45);
    final path = Path()..addRRect(rrect);
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 13) {
        canvas.drawPath(m.extractPath(d, math.min(d + 7, m.length)), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Thin curved arrow from the top piece toward the gold piece (page 1).
class CurvedArrow extends StatelessWidget {
  const CurvedArrow({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ArrowPainter());
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColor.darkGreenColor.withOpacity(0.85);
    const end = Offset(274, 100);
    final path = Path()
      ..moveTo(224, 28)
      ..quadraticBezierTo(288, 14, end.dx, end.dy);
    canvas.drawPath(path, p);
    canvas.drawLine(end, end.translate(-7, -11), p);
    canvas.drawLine(end, end.translate(8, -10), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

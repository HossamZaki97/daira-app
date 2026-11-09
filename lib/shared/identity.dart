import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';

/// Native vector equivalent of design/brand/people-circle/daira-people-circle.svg.
/// Keeps the approved geometry without a runtime SVG dependency.
class DairaMark extends StatelessWidget {
  const DairaMark({this.size = 44, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter()),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 512, size.height / 512);
    canvas.translate(0, 37.75);
    final paint = Paint()..color = AppColors.primary;
    final body = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: const Offset(256, 256), radius: 140))
      ..moveTo(158.13913, 199.5)
      ..arcToPoint(
        const Offset(207.92409, 153.73707),
        radius: const Radius.circular(113),
      )
      ..arcToPoint(
        const Offset(304.07591, 153.73707),
        radius: const Radius.circular(50),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(368.60025, 265.49651),
        radius: const Radius.circular(113),
      )
      ..arcToPoint(
        const Offset(320.52434, 348.76642),
        radius: const Radius.circular(50),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(191.47566, 348.76642),
        radius: const Radius.circular(113),
      )
      ..arcToPoint(
        const Offset(143.39975, 265.49651),
        radius: const Radius.circular(50),
        clockwise: false,
      )
      ..arcToPoint(
        const Offset(158.13913, 199.5),
        radius: const Radius.circular(113),
      )
      ..close();
    canvas.drawPath(body, paint);
    for (var index = 0; index < 3; index++) {
      final angle = index * math.pi * 2 / 3;
      canvas.drawCircle(
        Offset(256 + 185 * math.sin(angle), 256 - 185 * math.cos(angle)),
        30.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

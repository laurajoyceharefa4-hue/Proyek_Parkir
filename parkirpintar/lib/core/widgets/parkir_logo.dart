import 'package:flutter/material.dart';

import '../app_colors.dart';

class ParkirLogo extends StatelessWidget {
  const ParkirLogo({super.key, this.size = 104, this.onDark = true});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Logo ParkirPintar',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _ParkirLogoPainter(onDark: onDark)),
      ),
    );
  }
}

class _ParkirLogoPainter extends CustomPainter {
  const _ParkirLogoPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final glow = Paint()..color = AppColors.brandBright.withAlpha(65);
    canvas.drawCircle(
      center.translate(0, -size.height * 0.05),
      radius * 1.35,
      glow,
    );

    final pin = Path()
      ..moveTo(center.dx, size.height * 0.88)
      ..cubicTo(
        size.width * 0.08,
        size.height * 0.57,
        size.width * 0.2,
        size.height * 0.14,
        center.dx,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.8,
        size.height * 0.14,
        size.width * 0.92,
        size.height * 0.57,
        center.dx,
        size.height * 0.88,
      )
      ..close();
    canvas.drawPath(pin, Paint()..color = AppColors.brand);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          color: onDark ? AppColors.surface : AppColors.brandDark,
          fontSize: size.width * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, size.height * 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _ParkirLogoPainter oldDelegate) =>
      oldDelegate.onDark != onDark;
}

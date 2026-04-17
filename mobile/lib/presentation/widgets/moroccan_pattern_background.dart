import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fond style riad : dégradé sable + zellij (étoiles, losanges, filets or).
class MoroccanPatternBackground extends StatelessWidget {
  const MoroccanPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.sand,
                  AppColors.sandDeep.withValues(alpha: 0.85),
                  AppColors.sand,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _ZellijFieldPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _ZellijFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _stars(canvas, size);
    _diamondMesh(canvas, size);
    _glazeDots(canvas, size);
    _goldWeave(canvas, size);
  }

  void _stars(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.deepBlue.withValues(alpha: 0.09);

    const step = 52.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        _star(canvas, Offset(x, y), 11, p);
      }
    }

    final pSmall = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = AppColors.zellijGlaze.withValues(alpha: 0.07);
    for (double y = -step / 2; y < size.height + step; y += step) {
      for (double x = -step / 2; x < size.width + step; x += step) {
        _star(canvas, Offset(x, y), 5.5, pSmall);
      }
    }
  }

  void _diamondMesh(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65
      ..color = AppColors.gold.withValues(alpha: 0.07);

    const g = 36.0;
    for (double y = 0; y < size.height + g; y += g) {
      for (double x = 0; x < size.width + g; x += g) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(math.pi / 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: g * 0.5, height: g * 0.5),
            const Radius.circular(2),
          ),
          p,
        );
        canvas.restore();
      }
    }
  }

  void _glazeDots(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.zellijGlaze.withValues(alpha: 0.06);
    const step = 88.0;
    for (double y = 22; y < size.height; y += step) {
      for (double x = 44; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 2.2, p);
      }
    }
  }

  void _goldWeave(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = AppColors.gold.withValues(alpha: 0.06);
    for (double i = -size.height; i < size.width + size.height; i += 64) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height * 0.92, size.height), p);
    }
    for (double i = 0; i < size.width + size.height; i += 64) {
      canvas.drawLine(Offset(i, size.height), Offset(i - size.height * 0.92, 0), p);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    const n = 8;
    final path = Path();
    for (int i = 0; i < n; i++) {
      final a = (i * math.pi * 2 / n) - math.pi / 2;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Carte style « cadre zellige » : filet or, ombre douce, étoiles aux coins.
class MoroccanCard extends StatelessWidget {
  const MoroccanCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final inner = CustomPaint(
      foregroundPainter: _ZellijCornerPainter(),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlue.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.terracotta.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(22),
                child: inner,
              ),
            ),
    );
  }
}

class _ZellijCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const r = 14.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..color = AppColors.deepBlue.withValues(alpha: 0.38);

    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.gold.withValues(alpha: 0.72);

    void star(Offset c) {
      _drawStar(canvas, c, r, paint);
      _drawStar(canvas, c, r * 0.45, gold);
    }

    star(Offset(r * 0.35, r * 0.35));
    star(Offset(size.width - r * 0.35, r * 0.35));
    star(Offset(r * 0.35, size.height - r * 0.35));
    star(Offset(size.width - r * 0.35, size.height - r * 0.35));
  }

  void _drawStar(Canvas canvas, Offset c, double radius, Paint paint) {
    const n = 8;
    final path = Path();
    for (int i = 0; i < n; i++) {
      final a = (i * math.pi * 2 / n) - math.pi / 2;
      final p = Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
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

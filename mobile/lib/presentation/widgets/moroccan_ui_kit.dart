import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Filet horizontal type « bande zellige » or.
class MoroccanGoldBand extends StatelessWidget {
  const MoroccanGoldBand({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0),
            AppColors.gold,
            AppColors.terracotta.withValues(alpha: 0.85),
            AppColors.gold,
            AppColors.gold.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

/// Titre de section avec style El Messiri.
class MoroccanSectionTitle extends StatelessWidget {
  const MoroccanSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.gold.withValues(alpha: 0.35))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: GoogleFonts.elMessiri(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.deepBlue,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.gold.withValues(alpha: 0.35))),
      ],
    );
  }
}

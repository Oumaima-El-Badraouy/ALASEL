import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Titre avec ligne or / zellij et sous-titre arabe optionnel.
class MoroccanSectionHeader extends StatelessWidget {
  const MoroccanSectionHeader({
    super.key,
    required this.title,
    this.arabic,
    this.subtitle,
  });

  final String title;
  final String? arabic;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (arabic != null)
          Text(
            arabic!,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.zellijGlaze,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (arabic != null) const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.deepBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 8),
        Container(
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.85),
                AppColors.gold.withValues(alpha: 0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

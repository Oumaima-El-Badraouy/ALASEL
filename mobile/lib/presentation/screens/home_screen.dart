import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_card.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/moroccan_section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MoroccanPatternBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const MoroccanSectionHeader(
                arabic: 'مرحبا — الأصل',
                title: 'Bienvenue',
                subtitle: 'Motifs zellij, couleurs du Maroc : confiance et artisanat authentique.',
              ),
              const SizedBox(height: 20),
              _ctaCard(
                context,
                title: 'Explorer les artisans',
                titleAr: 'استكشف الحرفيين',
                subtitle: 'Métier, ville, disponibilité, avis',
                icon: Icons.search_rounded,
                onTap: () => context.push('/explore'),
              ),
              _ctaCard(
                context,
                title: 'Poster une demande',
                titleAr: 'طلب خدمة',
                subtitle: 'Estimation & matching',
                icon: Icons.edit_calendar_outlined,
                onTap: () => context.push('/request'),
              ),
              _ctaCard(
                context,
                title: 'Espace artisan',
                titleAr: 'فضاء الحرفي',
                subtitle: 'Profil, portfolio avant/après',
                icon: Icons.handyman_outlined,
                onTap: () => context.push('/artisan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ctaCard(
    BuildContext context, {
    required String title,
    required String titleAr,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MoroccanCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.28),
                  AppColors.terracotta.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: AppColors.deepBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleAr,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.zellijGlaze,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

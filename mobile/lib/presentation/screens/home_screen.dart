import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_pattern_background.dart';

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
              Text(
                'مرحبا',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.deepBlue,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Trouvez un artisan de confiance — vite, clair, sans surprise.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              _ctaCard(
                context,
                title: 'Explorer les artisans',
                subtitle: 'Filtres: métier, ville, disponibilité, avis',
                icon: Icons.search_rounded,
                onTap: () => context.push('/explore'),
              ),
              _ctaCard(
                context,
                title: 'Poster une demande',
                subtitle: 'Smart matching + estimation de prix',
                icon: Icons.edit_calendar_outlined,
                onTap: () => context.push('/request'),
              ),
              _ctaCard(
                context,
                title: 'Espace artisan',
                subtitle: 'Profil, portfolio avant/après, messages',
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
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.deepBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

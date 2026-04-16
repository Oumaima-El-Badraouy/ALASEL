import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/artisan_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

final _artisanProvider = FutureProvider.autoDispose.family<ArtisanModel, String>((ref, id) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.getArtisan(id);
});

class ArtisanDetailScreen extends ConsumerWidget {
  const ArtisanDetailScreen({super.key, required this.artisanId});

  final String artisanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_artisanProvider(artisanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil artisan')),
      body: MoroccanPatternBackground(
        child: async.when(
          data: (a) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.3),
                    child: Text(
                      a.displayName.isEmpty ? '?' : a.displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepBlue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text('Trust ${a.trustScore} · ${a.avgRating ?? 0}★ (${a.reviewCount ?? 0})',
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.bio ?? '', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text('Portfolio — avant / après', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (a.portfolio.isEmpty)
                const Text('Pas encore de photos.', style: TextStyle(color: AppColors.muted))
              else
                ...a.portfolio.map((p) => _PortfolioCard(item: p)),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.caption ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (item.type == 'before_after')
              Row(
                children: [
                  Expanded(child: _Img(url: item.beforeUrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _Img(url: item.afterUrl)),
                ],
              )
            else
              _Img(url: item.afterUrl ?? item.beforeUrl),
          ],
        ),
      ),
    );
  }
}

class _Img extends StatelessWidget {
  const _Img({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url ?? '';
    if (u.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.deepBlue.withValues(alpha: 0.08)),
        ),
        child: const Center(child: Text('—', style: TextStyle(color: AppColors.muted))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(imageUrl: u, height: 120, fit: BoxFit.cover),
    );
  }
}

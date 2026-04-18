import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/strings.dart';
import '../../data/models/artisan_model.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/artisan_public_detail.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_app_bar.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_card.dart';

final _artisanFullProvider = FutureProvider.autoDispose.family<ArtisanPublicDetail, String>((ref, id) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.getArtisanFull(id);
});

class ArtisanDetailScreen extends ConsumerWidget {
  const ArtisanDetailScreen({super.key, required this.artisanId});

  final String artisanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_artisanFullProvider(artisanId));

    return Scaffold(
      appBar: MoroccanAppBar(
        title: Text(
          S.artisanDetailSubtitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.zellijGlaze),
        ),
      ),
      body: MoroccanPatternBackground(
        child: async.when(
          data: (d) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(_artisanFullProvider(artisanId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfilePhoto(photoUrl: d.photoUrl, label: d.fullName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(d),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${S.trustWord} ${d.profile.trustScore} · ${d.profile.avgRating ?? 0}★ (${d.profile.reviewCount ?? 0})',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                          if (d.phone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(
                              '${S.phoneNumberPrefix}${d.phone}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.deepBlue),
                            ),
                          ],
                          if (d.location != null && d.location!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.place_outlined, size: 18, color: AppColors.muted.withValues(alpha: 0.9)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    d.location!.trim(),
                                    style: const TextStyle(fontSize: 13, color: AppColors.ink),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in d.profile.categories)
                      Chip(
                        label: Text(S.categoryLabel(c), style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  d.description.isNotEmpty ? d.description : (d.profile.bio ?? ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        value: '${d.servicePostsCount}',
                        label: S.statServicePosts,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatBox(
                        value: '${d.demandsInTradeCount}',
                        label: S.statDemandsInTrade,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  S.artisanPostsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (d.posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(S.noPosts, style: TextStyle(color: AppColors.muted)),
                  )
                else
                  ...d.posts.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(
                        post: p,
                        showChat: true,
                        showFollow: false,
                        onEngagementChanged: () => ref.invalidate(_artisanFullProvider(artisanId)),
                      ),
                    ),
                  ),
                if (d.profile.portfolio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    S.portfolioSection,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  ...d.profile.portfolio.map((p) => _PortfolioCard(item: p)),
                ],
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }

  static String _displayName(ArtisanPublicDetail d) {
    final fn = (d.firstName ?? '').trim();
    final ln = (d.lastName ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    if (d.fullName.isNotEmpty) return d.fullName;
    return d.profile.displayName;
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandDeep),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.photoUrl, required this.label});

  final String? photoUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = photoUrl;
    if (p != null && p.startsWith('data:image')) {
      try {
        final bytes = base64Decode(p.split(',').last);
        return CircleAvatar(radius: 40, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    if (p != null && (p.startsWith('http://') || p.startsWith('https://'))) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: p,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.gold.withValues(alpha: 0.3),
      child: Text(
        label.isEmpty ? '?' : label.substring(0, 1).toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepBlue, fontSize: 28),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final caption = item.caption ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (caption.isNotEmpty) Text(caption, style: const TextStyle(fontWeight: FontWeight.w600)),
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

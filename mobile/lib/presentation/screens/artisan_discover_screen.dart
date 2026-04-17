import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_card.dart';

final _discoverProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final me = await ref.watch(marketplaceRepositoryProvider).me();
  final all = await ref.watch(marketplaceRepositoryProvider).postsFeed(postType: 'artisan_service');
  return all.where((p) => p.userId != me.id).toList();
});

class ArtisanDiscoverScreen extends ConsumerWidget {
  const ArtisanDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_discoverProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Autres artisans')),
      body: MoroccanPatternBackground(
        child: async.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(child: Text('Aucun autre service publié.'));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_discoverProvider),
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(
                  post: posts[i],
                  showChat: true,
                  showFollow: false,
                  onEngagementChanged: () => ref.invalidate(_discoverProvider),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.muted))),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_card.dart';

final _demandsFeedProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  ref.watch(feedSocketTickProvider);
  return ref.watch(marketplaceRepositoryProvider).postsFeed(postType: 'client_request');
});

class ArtisanDemandsScreen extends ConsumerWidget {
  const ArtisanDemandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_demandsFeedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(S.clientDemandsScreenTitle)),
      body: MoroccanPatternBackground(
        child: async.when(
          data: (posts) {
            if (posts.isEmpty) {
              return const Center(child: Text(S.noDemandsYet));
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_demandsFeedProvider),
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(
                  post: posts[i],
                  showChat: true,
                  showFollow: false,
                  onEngagementChanged: () => ref.invalidate(_demandsFeedProvider),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/moroccan_trades.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_card.dart';

final _demandsFeedProvider = FutureProvider.autoDispose.family<List<PostModel>, String>((ref, catKey) async {
  ref.watch(feedSocketTickProvider);
  return ref.watch(marketplaceRepositoryProvider).postsFeed(
        postType: 'client_request',
        category: catKey.isEmpty ? null : catKey,
      );
});

class ArtisanDemandsScreen extends ConsumerStatefulWidget {
  const ArtisanDemandsScreen({super.key});

  @override
  ConsumerState<ArtisanDemandsScreen> createState() => _ArtisanDemandsScreenState();
}

class _ArtisanDemandsScreenState extends ConsumerState<ArtisanDemandsScreen> {
  String catKey = '';

  static List<String> get _cats => ['', ...moroccanTradeIds];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_demandsFeedProvider(catKey));

    return Scaffold(
      appBar: AppBar(title: const Text(S.clientDemandsScreenTitle)),
      body: MoroccanPatternBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  for (final c in _cats)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(S.categoryLabel(c), style: const TextStyle(fontSize: 13)),
                        selected: catKey == c,
                        onSelected: (_) => setState(() => catKey = c),
                        selectedColor: AppColors.terracotta.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.deepBlue,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Center(child: Text(S.noDemandsYet));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(_demandsFeedProvider(catKey)),
                    child: ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (_, i) => PostCard(
                        post: posts[i],
                        showChat: true,
                        showFollow: false,
                        onEngagementChanged: () => ref.invalidate(_demandsFeedProvider(catKey)),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.muted))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

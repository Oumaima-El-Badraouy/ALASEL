import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_card.dart';

final _myServicePostsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  ref.watch(feedSocketTickProvider);
  final all = await ref.watch(marketplaceRepositoryProvider).myPosts();
  return all.where((p) => p.isService).toList();
});

class ArtisanMyPostsScreen extends ConsumerWidget {
  const ArtisanMyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_myServicePostsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(S.navMyPosts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-post?type=artisan_service'),
        icon: const Icon(Icons.add),
        label: const Text(S.fabNew),
      ),
      body: MoroccanPatternBackground(
        child: async.when(
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/create-post?type=artisan_service'),
                  icon: const Icon(Icons.post_add),
                  label: const Text(S.createFirstServicePost),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_myServicePostsProvider),
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) {
                  final p = posts[i];
                  return Column(
                    children: [
                      PostCard(post: p, showChat: false),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            await ref.read(marketplaceRepositoryProvider).deletePost(p.id);
                            ref.invalidate(_myServicePostsProvider);
                          },
                          child: const Text(S.deleteAction, style: TextStyle(color: AppColors.terracotta)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

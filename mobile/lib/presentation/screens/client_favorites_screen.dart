import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/client_feed_post_card.dart';

final _favoritesFeedProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  return ref.watch(marketplaceRepositoryProvider).favoritePosts();
});

class ClientFavoritesScreen extends ConsumerWidget {
  const ClientFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_favoritesFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_favoritesFeedProvider);
          await ref.read(_favoritesFeedProvider.future);
        },
        child: CustomScrollView(
          slivers: [
              const SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppColors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0.5,
                title: Text(S.favoritesTitle, style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              async.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            S.favoritesEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, height: 1.4),
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _FavoritePostRow(
                          post: posts[i],
                          onFavoriteChanged: () => ref.invalidate(_favoritesFeedProvider),
                        ),
                        childCount: posts.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (e, _) => SliverFillRemaining(
                  child: Center(child: Text('$e', style: const TextStyle(color: AppColors.muted))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePostRow extends ConsumerWidget {
  const _FavoritePostRow({required this.post, required this.onFavoriteChanged});

  final PostModel post;
  final VoidCallback onFavoriteChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fol = ref.watch(artisanFollowStatusProvider(post.userId));
    return fol.when(
      data: (isF) => ClientFeedPostCard(
        post: post,
        isFollowing: isF,
        onFollowToggle: () async {
          final repo = ref.read(marketplaceRepositoryProvider);
          if (isF) {
            await repo.unfollowArtisan(post.userId);
          } else {
            await repo.followArtisan(post.userId);
          }
          ref.invalidate(artisanFollowStatusProvider(post.userId));
        },
        onFavoriteChanged: onFavoriteChanged,
        onEngagementChanged: () => ref.invalidate(_favoritesFeedProvider),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => ClientFeedPostCard(
        post: post,
        isFollowing: false,
        onFollowToggle: () {},
        onFavoriteChanged: onFavoriteChanged,
        onEngagementChanged: () => ref.invalidate(_favoritesFeedProvider),
      ),
    );
  }
}

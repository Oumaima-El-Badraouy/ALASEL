import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/client_feed_post_card.dart';

final _clientFeedProvider = FutureProvider.autoDispose.family<List<PostModel>, String>((ref, key) async {
  final parts = key.split('|');
  final cat = parts.isEmpty || parts[0].isEmpty ? null : parts[0];
  final sort = parts.length > 1 ? parts[1] : '';
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.postsFeed(
    category: cat,
    postType: 'artisan_service',
    sort: sort == 'popular' ? 'popular' : null,
  );
});

final _followProvider = FutureProvider.autoDispose.family<bool, String>((ref, artisanId) async {
  return ref.watch(marketplaceRepositoryProvider).isFollowing(artisanId);
});

class ClientFeedScreen extends ConsumerStatefulWidget {
  const ClientFeedScreen({super.key});

  @override
  ConsumerState<ClientFeedScreen> createState() => _ClientFeedScreenState();
}

class _ClientFeedScreenState extends ConsumerState<ClientFeedScreen> {
  String catKey = '';
  String sortMode = 'recent';

  static const cats = ['', 'plumbing', 'painting', 'carpentry', 'electricity', 'tiling', 'hvac'];

  String get _providerKey => '$catKey|$sortMode';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_clientFeedProvider(_providerKey));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_clientFeedProvider(_providerKey));
          await ref.read(_clientFeedProvider(_providerKey).future);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0.5,
              title: Row(
                children: [
                  Text(
                    'AL ASEL',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.deepBlue,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mediouna',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.terracotta.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sortMode,
                      icon: const Icon(Icons.sort, size: 22, color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(value: 'recent', child: Text('Récent')),
                        DropdownMenuItem(value: 'popular', child: Text('Popularité')),
                      ],
                      onChanged: (v) => setState(() => sortMode = v ?? 'recent'),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.isEmpty ? 'Tous' : c, style: const TextStyle(fontSize: 13)),
                          selected: catKey == c,
                          onSelected: (_) => setState(() => catKey = c),
                          selectedColor: AppColors.terracotta.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.deepBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            async.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('Aucune publication pour l’instant.')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PostRow(post: posts[i], feedKey: _providerKey),
                      childCount: posts.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('$e', style: const TextStyle(color: AppColors.muted))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostRow extends ConsumerWidget {
  const _PostRow({required this.post, required this.feedKey});

  final PostModel post;
  final String feedKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fol = ref.watch(_followProvider(post.userId));
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
          ref.invalidate(_followProvider(post.userId));
        },
        onEngagementChanged: () => ref.invalidate(_clientFeedProvider(feedKey)),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => ClientFeedPostCard(
        post: post,
        isFollowing: false,
        onFollowToggle: () {},
        onEngagementChanged: () => ref.invalidate(_clientFeedProvider(feedKey)),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import '../widgets/client_feed_post_card.dart';

final _clientFeedProvider = FutureProvider.autoDispose.family<List<PostModel>, String>((ref, key) async {
  ref.watch(feedSocketTickProvider);
  final parts = key.split('|');
  final cat = parts.isEmpty || parts[0].isEmpty ? null : parts[0];
  final sort = parts.length > 1 ? parts[1] : '';
  final q = parts.length > 2 ? parts[2] : '';
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.postsFeed(
    category: cat,
    postType: 'artisan_service',
    sort: sort == 'popular' ? 'popular' : null,
    q: q.isEmpty ? null : q,
  );
});

class ClientFeedScreen extends ConsumerStatefulWidget {
  const ClientFeedScreen({super.key});

  @override
  ConsumerState<ClientFeedScreen> createState() => _ClientFeedScreenState();
}

class _ClientFeedScreenState extends ConsumerState<ClientFeedScreen> {
  String catKey = '';
  String sortMode = 'recent';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const cats = ['', 'plumbing', 'painting', 'carpentry', 'electricity', 'tiling', 'hvac'];

  String get _providerKey => '$catKey|$sortMode|$_searchQuery';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _searchQuery = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_clientFeedProvider(_providerKey));

    return Scaffold(
      backgroundColor: AppColors.sand,
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
              backgroundColor: AppColors.parchment,
              surfaceTintColor: Colors.transparent,
              elevation: 1,
              shadowColor: AppColors.deepBlue.withValues(alpha: 0.08),
              title: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: S.searchHint,
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIcon: const Icon(Icons.search, color: AppColors.deepBlue, size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sortMode,
                      icon: const Icon(Icons.sort, size: 22, color: AppColors.ink),
                      items: [
                        DropdownMenuItem(value: 'recent', child: Text(S.sortRecent)),
                        DropdownMenuItem(value: 'popular', child: Text(S.sortPopular)),
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
            ),
            async.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(S.noPosts)),
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

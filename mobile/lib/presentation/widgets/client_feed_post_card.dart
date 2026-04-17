import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import 'author_avatar.dart';
import 'post_comments_sheet.dart';
import 'post_likers_sheet.dart';

/// Carte feed client : artisan, média, j’aime / commentaires, favoris, chat, suivre.
class ClientFeedPostCard extends ConsumerStatefulWidget {
  const ClientFeedPostCard({
    super.key,
    required this.post,
    required this.isFollowing,
    required this.onFollowToggle,
    this.onFavoriteChanged,
    this.onEngagementChanged,
  });

  final PostModel post;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback? onFavoriteChanged;
  final VoidCallback? onEngagementChanged;

  @override
  ConsumerState<ClientFeedPostCard> createState() => _ClientFeedPostCardState();
}

class _ClientFeedPostCardState extends ConsumerState<ClientFeedPostCard> {
  late int _likes;
  late int _comments;
  late bool _liked;
  bool _likeBusy = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ClientFeedPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) _sync();
  }

  void _sync() {
    _likes = widget.post.likesCount;
    _comments = widget.post.commentsCount;
    _liked = widget.post.likedByMe;
  }

  bool _net(String? m) => m != null && (m.startsWith('http://') || m.startsWith('https://'));
  bool _dataImg(String? m) => m != null && m.startsWith('data:image');

  Future<void> _toggleFavorite() async {
    final me = ref.read(authNotifierProvider).user;
    if (me == null) return;
    final fav = me.favoritePostIds.contains(widget.post.id);
    final repo = ref.read(marketplaceRepositoryProvider);
    if (fav) {
      await repo.removePostFavorite(widget.post.id);
    } else {
      await repo.addPostFavorite(widget.post.id);
    }
    await ref.read(authNotifierProvider.notifier).refreshMe();
    widget.onFavoriteChanged?.call();
  }

  Future<void> _toggleLike() async {
    final me = ref.read(authNotifierProvider).user;
    if (me == null || (me.role != 'client' && me.role != 'artisan') || _likeBusy) return;
    setState(() => _likeBusy = true);
    try {
      final m = await ref.read(marketplaceRepositoryProvider).togglePostLike(widget.post.id);
      if (!mounted) return;
      setState(() {
        _liked = m['liked'] as bool? ?? !_liked;
        _likes = (m['likesCount'] as num?)?.toInt() ?? _likes;
      });
      widget.onEngagementChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _likeBusy = false);
    }
  }

  void _openComments() {
    final me = ref.read(authNotifierProvider).user;
    if (me == null || (me.role != 'client' && me.role != 'artisan')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous en tant que client ou artisan pour commenter.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PostCommentsSheet(
        postId: widget.post.id,
        onCommentAdded: () {
          if (mounted) {
            setState(() => _comments++);
            widget.onEngagementChanged?.call();
          }
        },
        onEngagementChanged: widget.onEngagementChanged,
      ),
    );
  }

  void _openLikers() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PostLikersSheet(postId: widget.post.id),
    );
  }

  void _openChat() {
    final label = widget.post.authorDisplayName ?? 'Artisan';
    final loc = Uri(
      path: '/chat/${widget.post.userId}',
      queryParameters: {'name': label},
    ).toString();
    context.push(loc);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authNotifierProvider).user;
    final isClient = me?.role == 'client';
    final canEngage = me != null && (me.role == 'client' || me.role == 'artisan');
    final isMine = me?.id == widget.post.userId;
    final isFav = me?.favoritePostIds.contains(widget.post.id) ?? false;
    final author = widget.post.authorDisplayName ?? 'Artisan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.sandDeep),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorAvatar(
                  radius: 18,
                  photoUrl: widget.post.authorPhotoUrl,
                  fallbackLabel: author,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.post.category != null && widget.post.category!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('#${widget.post.category}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine)
                      widget.isFollowing
                          ? OutlinedButton(
                              onPressed: widget.onFollowToggle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.deepBlue,
                                side: const BorderSide(color: AppColors.deepBlue),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Abonné',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            )
                          : FilledButton(
                              onPressed: widget.onFollowToggle,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.deepBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Suivre',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                    if (widget.post.city != null && widget.post.city!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: !isMine ? 6 : 0),
                        child: Text(
                          widget.post.city!,
                          style: TextStyle(fontSize: 11, color: AppColors.terracotta.withValues(alpha: 0.9)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.post.media != null && widget.post.media!.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: _net(widget.post.media)
                  ? CachedNetworkImage(imageUrl: widget.post.media!, fit: BoxFit.cover)
                  : _dataImg(widget.post.media)
                      ? Image.memory(
                          base64Decode(widget.post.media!.split(',').last),
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: AppColors.sandDeep,
                          child: Icon(Icons.play_circle_outline, size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
                        ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 4),
            child: LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 340;
                return Wrap(
                  spacing: 0,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (canEngage)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _likeBusy ? null : _toggleLike,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: _likeBusy
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Icon(
                                        _liked ? Icons.favorite : Icons.favorite_border,
                                        color: _liked ? AppColors.terracotta : AppColors.ink,
                                        size: narrow ? 22 : 24,
                                      ),
                              ),
                            ),
                            InkWell(
                              onTap: _openLikers,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                                child: Text(
                                  '$_likes',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: narrow ? 13 : 14,
                                    color: AppColors.deepBlue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (canEngage)
                      Tooltip(
                        message: 'Commentaires publics sur ce post',
                        child: InkWell(
                          onTap: _openComments,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.forum_outlined, size: narrow ? 22 : 24, color: AppColors.ink),
                                const SizedBox(width: 4),
                                Text(
                                  '$_comments',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: narrow ? 13 : 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (isClient)
                      IconButton(
                        tooltip: isFav ? 'Retirer des favoris' : 'Favori',
                        onPressed: isMine ? null : _toggleFavorite,
                        icon: Icon(
                          isFav ? Icons.bookmark : Icons.bookmark_border,
                          color: isFav ? AppColors.terracotta : AppColors.ink,
                        ),
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                    IconButton(
                      tooltip: 'Message privé à l’artisan',
                      onPressed: isMine ? null : _openChat,
                      icon: const Icon(Icons.send_rounded),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              widget.post.content,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

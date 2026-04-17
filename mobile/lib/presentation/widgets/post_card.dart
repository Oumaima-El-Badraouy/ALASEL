import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../providers/app_providers.dart';
import 'moroccan_card.dart';
import 'post_comments_sheet.dart';
import 'post_likers_sheet.dart';

class PostCard extends ConsumerStatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showChat = true,
    this.showFollow = false,
    this.isFollowing = false,
    this.onFollowToggle,
    this.onEngagementChanged,
  });

  final PostModel post;
  final bool showChat;
  final bool showFollow;
  final bool isFollowing;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onEngagementChanged;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
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
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) _sync();
  }

  void _sync() {
    _likes = widget.post.likesCount;
    _comments = widget.post.commentsCount;
    _liked = widget.post.likedByMe;
  }

  bool _isNetworkImage(String? m) {
    if (m == null || m.isEmpty) return false;
    return m.startsWith('http://') || m.startsWith('https://');
  }

  bool _isDataImage(String? m) {
    return m != null && m.startsWith('data:image');
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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authNotifierProvider).user;
    final isMine = me?.id == widget.post.userId;
    final canEngage = me != null && (me.role == 'client' || me.role == 'artisan');

    return MoroccanCard(
      onTap: null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.post.isService
                      ? AppColors.gold.withValues(alpha: 0.2)
                      : AppColors.terracotta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.post.isService ? 'Service' : 'Demande',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.post.category != null && widget.post.category!.isNotEmpty)
                Text('#${widget.post.category}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
          if (widget.post.media != null && widget.post.media!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: _isNetworkImage(widget.post.media)
                    ? CachedNetworkImage(imageUrl: widget.post.media!, fit: BoxFit.cover)
                    : _isDataImage(widget.post.media)
                        ? Image.memory(
                            base64Decode(widget.post.media!.split(',').last),
                            fit: BoxFit.cover,
                          )
                        : const ColoredBox(
                            color: AppColors.sandDeep,
                            child: Center(child: Icon(Icons.image_not_supported_outlined)),
                          ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(widget.post.content, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
          const SizedBox(height: 10),
          if (canEngage)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _likeBusy ? null : _toggleLike,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _likeBusy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                size: 22,
                                color: _liked ? AppColors.terracotta : AppColors.ink,
                              ),
                      ),
                    ),
                    InkWell(
                      onTap: _openLikers,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Text(
                          '$_likes',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _openComments,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.forum_outlined, size: 22, color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text('$_comments', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.showChat && !isMine)
                OutlinedButton.icon(
                  onPressed: () {
                    final label = widget.post.content.length > 40
                        ? '${widget.post.content.substring(0, 40)}…'
                        : widget.post.content;
                    final loc = Uri(
                      path: '/chat/${widget.post.userId}',
                      queryParameters: {'name': label},
                    ).toString();
                    context.push(loc);
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Message'),
                ),
              if (widget.showFollow && widget.post.isService && !isMine) ...[
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: widget.onFollowToggle,
                  child: Text(widget.isFollowing ? 'Abonné' : 'Suivre'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

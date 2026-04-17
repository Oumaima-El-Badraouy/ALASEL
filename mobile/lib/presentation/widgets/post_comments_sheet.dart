import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_comment_model.dart';
import '../providers/app_providers.dart';

/// Feuille modale : commentaires (prénom + nom) + chat / suivre par ligne.
class PostCommentsSheet extends ConsumerStatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.postId,
    this.onCommentAdded,
    this.onEngagementChanged,
  });

  final String postId;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onEngagementChanged;

  @override
  ConsumerState<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends ConsumerState<PostCommentsSheet> {
  final _text = TextEditingController();
  List<PostCommentModel> _items = [];
  bool _loading = true;
  String? _err;
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await ref.read(marketplaceRepositoryProvider).postComments(widget.postId);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(marketplaceRepositoryProvider).addPostComment(widget.postId, t);
      _text.clear();
      await _load();
      widget.onCommentAdded?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _canChat(String? meId, String? meRole, PostCommentModel c) {
    if (meId == null || c.userId == meId) return false;
    final ar = c.authorRole;
    if (meRole == 'client' && ar == 'artisan') return true;
    if (meRole == 'artisan' && ar == 'client') return true;
    return false;
  }

  bool _canFollow(String? meRole, PostCommentModel c, String? meId) {
    return meRole == 'client' && c.authorRole == 'artisan' && c.userId != meId;
  }

  Future<void> _openChat(PostCommentModel c) async {
    final loc = Uri(
      path: '/chat/${c.userId}',
      queryParameters: {'name': c.displayNameLine},
    ).toString();
    await context.push(loc);
  }

  Future<void> _toggleFollow(PostCommentModel c) async {
    final repo = ref.read(marketplaceRepositoryProvider);
    try {
      final following = await repo.isFollowing(c.userId);
      if (following) {
        await repo.unfollowArtisan(c.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abonnement retiré')));
        }
      } else {
        await repo.followArtisan(c.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vous suivez cet artisan')));
        }
      }
      widget.onEngagementChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.72;
    final me = ref.watch(authNotifierProvider).user;
    final canWrite = me != null && (me.role == 'client' || me.role == 'artisan');

    return SafeArea(
      child: SizedBox(
        height: h,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _err != null
                      ? Center(child: Text(_err!, style: const TextStyle(color: AppColors.muted)))
                      : _items.isEmpty
                          ? const Center(
                              child: Text('Aucun commentaire. Soyez le premier.', style: TextStyle(color: AppColors.muted)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 4),
                              itemBuilder: (_, i) {
                                final c = _items[i];
                                final initial = c.displayNameLine.isNotEmpty ? c.displayNameLine[0].toUpperCase() : '?';
                                final roleLabel = c.authorRole == 'artisan'
                                    ? 'Artisan'
                                    : (c.authorRole == 'client' ? 'Client' : '');
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.terracotta.withValues(alpha: 0.2),
                                        child: Text(
                                          initial,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    c.displayNameLine,
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                                  ),
                                                ),
                                                if (roleLabel.isNotEmpty)
                                                  Text(
                                                    roleLabel,
                                                    style: TextStyle(fontSize: 11, color: AppColors.muted.withValues(alpha: 0.9)),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(c.text, style: const TextStyle(height: 1.35)),
                                            if (me != null &&
                                                (_canChat(me.id, me.role, c) || _canFollow(me.role, c, me.id))) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: [
                                                  if (_canChat(me.id, me.role, c))
                                                    OutlinedButton.icon(
                                                      onPressed: () => _openChat(c),
                                                      icon: const Icon(Icons.send_rounded, size: 16),
                                                      label: const Text('Message'),
                                                      style: OutlinedButton.styleFrom(
                                                        visualDensity: VisualDensity.compact,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      ),
                                                    ),
                                                  if (_canFollow(me.role, c, me.id))
                                                    FilledButton.tonal(
                                                      onPressed: () => _toggleFollow(c),
                                                      style: FilledButton.styleFrom(
                                                        visualDensity: VisualDensity.compact,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      ),
                                                      child: const Text('Suivre'),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
            if (canWrite)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Ajouter un commentaire…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

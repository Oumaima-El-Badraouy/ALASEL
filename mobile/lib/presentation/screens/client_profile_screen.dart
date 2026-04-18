import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../providers/app_providers.dart';
import '../widgets/author_avatar.dart';
import '../widgets/cin_upload_section.dart';

final _myDemandsProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  ref.watch(feedSocketTickProvider);
  final all = await ref.watch(marketplaceRepositoryProvider).myPosts();
  return all.where((p) => p.isDemand).toList();
});

final _followingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final m = await ref.watch(marketplaceRepositoryProvider).myFollowing();
  return (m['count'] as num?)?.toInt() ?? 0;
});

Future<void> _editClientLocation(BuildContext context, WidgetRef ref, String? current) async {
  final c = TextEditingController(text: current ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(S.locationSectionTitle),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: S.fieldLocationRequired,
          hintText: S.fieldLocationHint,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.saveLocationButton)),
      ],
    ),
  );
  final text = c.text.trim();
  c.dispose();
  if (ok != true || !context.mounted) return;
  if (text.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.errLocationRequired)));
    return;
  }
  await ref.read(marketplaceRepositoryProvider).patchMe({'location': text});
  await ref.read(authNotifierProvider.notifier).refreshMe();
}

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  static String _handle(UserModel u) {
    final f = (u.firstName ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final l = (u.lastName ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (f.isNotEmpty && l.isNotEmpty) return '${f}_$l';
    if (f.isNotEmpty) return f;
    final email = u.email;
    final at = email.indexOf('@');
    return at > 0 ? email.substring(0, at) : 'profil';
  }

  static String _fullName(UserModel u) {
    final fn = (u.firstName ?? '').trim();
    final ln = (u.lastName ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return u.display;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final u = auth.user;
    final demandsAsync = ref.watch(_myDemandsProvider);
    final followingAsync = ref.watch(_followingCountProvider);

    return Scaffold(
      backgroundColor: AppColors.sand,
      body: u == null
          ? const Center(child: Text(S.notLoggedIn))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0.5,
                  title: Text(_handle(u), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined),
                      tooltip: S.newDemandTooltip,
                      onPressed: () => context.push('/create-post?type=client_request'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _menuSheet(context, ref, u),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _profileAvatar(u, 44),
                            const SizedBox(width: 28),
                            Expanded(
                              child: followingAsync.when(
                                data: (n) => demandsAsync.when(
                                  data: (d) => Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _statColumn(context, '${d.length}', S.statDemands),
                                      _statColumn(context, '$n', S.statFollows),
                                    ],
                                  ),
                                  loading: () => const SizedBox(height: 40),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                                loading: () => const SizedBox(height: 40),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName(u),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(u.email, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.place_outlined, size: 20, color: AppColors.deepBlue.withValues(alpha: 0.75)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    S.locationSectionTitle,
                                    style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (u.location != null && u.location!.trim().isNotEmpty) ? u.location!.trim() : '—',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: S.saveLocationButton,
                              onPressed: () => _editClientLocation(context, ref, u.location),
                            ),
                          ],
                        ),
                        if (u.isMediounaVerified == true) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.verified_outlined, size: 16, color: AppColors.deepBlue.withValues(alpha: 0.8)),
                              const SizedBox(width: 4),
                              Text(S.mediouna, style: TextStyle(fontSize: 13, color: AppColors.deepBlue.withValues(alpha: 0.85))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Text(
                          S.myDemandsSection,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: CinUploadSection(),
                  ),
                ),
                demandsAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            S.noDemandsHint,
                            style: TextStyle(color: AppColors.muted.withValues(alpha: 0.9)),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final p = list[i];
                          return _DemandTile(
                            post: p,
                            onDelete: () => _confirmDelete(context, ref, p.id),
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Padding(padding: const EdgeInsets.all(20), child: Text('$e')),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  static Widget _profileAvatar(UserModel u, double r) {
    final p = u.photoUrl;
    if (p != null && p.startsWith('data:image')) {
      try {
        final bytes = base64Decode(p.split(',').last);
        return CircleAvatar(radius: r, backgroundImage: MemoryImage(bytes));
      } catch (_) {}
    }
    if (p != null && (p.startsWith('http://') || p.startsWith('https://'))) {
      return CircleAvatar(radius: r, backgroundImage: NetworkImage(p));
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
      child: Text(
        _initials(u),
        style: TextStyle(fontSize: r * 0.65, fontWeight: FontWeight.w800, color: AppColors.deepBlue),
      ),
    );
  }

  static String _initials(UserModel u) {
    final a = (u.firstName ?? u.name ?? '').trim();
    final b = (u.lastName ?? '').trim();
    if (a.isNotEmpty && b.isNotEmpty) {
      return '${a[0]}${b[0]}'.toUpperCase();
    }
    if (a.isNotEmpty) return a.substring(0, a.length >= 2 ? 2 : 1).toUpperCase();
    if (u.email.isNotEmpty) return u.email[0].toUpperCase();
    return '?';
  }

  static Widget _statColumn(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }

  void _menuSheet(BuildContext context, WidgetRef ref, UserModel u) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text(S.editProfile),
              onTap: () {
                Navigator.pop(ctx);
                _editSheet(context, ref, u);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(S.logout),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/auth/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.deleteRequestTitle),
        content: const Text(S.deleteRequestBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.terracotta),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(S.deleteAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(marketplaceRepositoryProvider).deletePost(postId);
      ref.invalidate(_myDemandsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.requestDeletedSnack)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _editSheet(BuildContext context, WidgetRef ref, UserModel user) {
    final first = TextEditingController(text: user.firstName ?? '');
    final last = TextEditingController(text: user.lastName ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(S.editSheetTitle, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(controller: first, decoration: const InputDecoration(labelText: S.fieldFirstName)),
            FormSpacing.betweenInputs,
            TextField(controller: last, decoration: const InputDecoration(labelText: S.fieldLastName)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref.read(marketplaceRepositoryProvider).patchMe({
                  'firstName': first.text.trim(),
                  'lastName': last.text.trim(),
                });
                await ref.read(authNotifierProvider.notifier).refreshMe();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(S.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemandTile extends StatelessWidget {
  const _DemandTile({required this.post, required this.onDelete});

  final PostModel post;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.sandDeep)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthorAvatar(
              radius: 22,
              photoUrl: post.authorPhotoUrl,
              fallbackLabel: post.authorDisplayName ?? S.meLabel,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.category != null && post.category!.isNotEmpty)
                    Text('#${post.category}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(post.content, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.35)),
                ],
              ),
            ),
            IconButton(
              tooltip: S.deleteTooltip,
              icon: const Icon(Icons.delete_outline, color: AppColors.terracotta),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

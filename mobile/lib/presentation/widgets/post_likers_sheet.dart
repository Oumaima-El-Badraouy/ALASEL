import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import 'author_avatar.dart';

/// Liste des personnes qui ont aimé un post.
class PostLikersSheet extends ConsumerStatefulWidget {
  const PostLikersSheet({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostLikersSheet> createState() => _PostLikersSheetState();
}

class _PostLikersSheetState extends ConsumerState<PostLikersSheet> {
  bool _loading = true;
  String? _err;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await ref.read(marketplaceRepositoryProvider).postLikers(widget.postId);
      if (mounted) setState(() => _items = list);
    } catch (e) {
      if (mounted) setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _line(Map<String, dynamic> m) {
    final fn = (m['firstName'] as String? ?? '').trim();
    final ln = (m['lastName'] as String? ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return (m['authorDisplayName'] as String?)?.trim() ?? 'Utilisateur';
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * 0.55;
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
                  const Text('J’aime', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
                              child: Text('Personne pour l’instant.', style: TextStyle(color: AppColors.muted)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final m = _items[i];
                                final role = m['role'] as String? ?? '';
                                final label = role == 'artisan' ? 'Artisan' : (role == 'client' ? 'Client' : '');
                                return ListTile(
                                  leading: AuthorAvatar(
                                    radius: 22,
                                    photoUrl: m['photoUrl'] as String?,
                                    fallbackLabel: _line(m),
                                  ),
                                  title: Text(_line(m), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: label.isEmpty ? null : Text(label, style: const TextStyle(fontSize: 12)),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

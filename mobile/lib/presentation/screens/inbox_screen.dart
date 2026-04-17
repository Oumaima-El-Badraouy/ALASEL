import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/responsive_content.dart';

/// Liste des conversations (messages reçus / envoyés).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  bool _loading = true;
  String? _err;
  List<Map<String, dynamic>> _items = [];

  Future<void> _load() async {
    setState(() {
      _err = null;
      _loading = true;
    });
    try {
      final list = await ref.read(marketplaceRepositoryProvider).listConversations();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
      ref.invalidate(inboxUnreadTotalProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _err = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: ResponsiveContent(
        maxWidth: 560,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _err != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_err!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _items.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('Aucun message pour l’instant.')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final c = _items[i];
                              final peerId = c['peerId'] as String? ?? '';
                              final name = c['peerDisplayName'] as String? ?? 'Chat';
                              final unread = (c['unreadCount'] as num?)?.toInt() ?? 0;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.deepBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                trailing: unread > 0
                                    ? Badge(
                                        label: Text('$unread'),
                                        child: const Icon(Icons.chevron_right),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: () async {
                                  final loc = Uri(
                                    path: '/chat/$peerId',
                                    queryParameters: {'name': name},
                                  ).toString();
                                  await context.push(loc);
                                  if (mounted) _load();
                                },
                              );
                            },
                          ),
                  ),
      ),
    );
  }
}

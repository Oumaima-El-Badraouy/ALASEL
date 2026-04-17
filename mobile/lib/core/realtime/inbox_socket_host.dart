import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_keys.dart';
import '../auth/auth_notifier.dart';
import '../l10n/strings.dart';
import '../../presentation/providers/app_providers.dart';
import 'socket_hub.dart';

/// Connexion Socket.IO : salle `user:{id}` — messages, commentaires, **nouvelles demandes (artisans)** + tick fils.
/// Les alertes « nouveau service » ne sont plus diffusées à tous les clients (voir API `createPost`).
class InboxSocketHost extends ConsumerStatefulWidget {
  const InboxSocketHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<InboxSocketHost> createState() => _InboxSocketHostState();
}

class _InboxSocketHostState extends ConsumerState<InboxSocketHost> {
  String? _boundUid;

  void _teardown() {
    ref.read(socketHubProvider).disconnect();
    _boundUid = null;
  }

  String _messageFor(dynamic raw) {
    if (raw is Map) {
      final t = raw['type'];
      if (t == 'new_demand') return S.notifNewDemand;
      if (t == 'new_service') return S.notifNewService;
      if (t == 'new_message') return S.newInboxNotification;
      if (t == 'new_comment') return S.notifNewComment;
    }
    return S.newInboxNotification;
  }

  void _bind(String? uid) {
    final hub = ref.read(socketHubProvider);
    if (uid == null || uid.isEmpty) {
      _teardown();
      return;
    }
    if (uid == _boundUid) return;

    hub.onInboxPing = (raw) {
      ref.invalidate(inboxUnreadTotalProvider);
      if (raw is Map) {
        final t = raw['type'];
        // Rafraîchir les fils seulement quand une nouvelle demande est publiée (notifs ciblées artisans).
        if (t == 'new_demand') {
          ref.read(feedSocketTickProvider.notifier).state++;
        }
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(_messageFor(raw)),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    };
    hub.connect(uid);
    _boundUid = uid;
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authNotifierProvider.select((a) => a.user?.id));
    if (uid != _boundUid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bind(uid);
      });
    }
    return widget.child;
  }
}

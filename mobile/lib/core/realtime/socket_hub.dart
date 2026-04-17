import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';

/// Une seule connexion Socket.IO partagée : `join_user`, `join_conversation`, événements temps réel.
final socketHubProvider = Provider<SocketHub>((ref) {
  final hub = SocketHub();
  ref.onDispose(hub.dispose);
  return hub;
});

class SocketHub {
  io.Socket? _socket;
  String? _boundUid;
  final Set<String> _joinedConversations = {};

  /// Callback pour `inbox_ping` (assigné par [InboxSocketHost]).
  void Function(dynamic raw)? onInboxPing;

  final List<void Function(dynamic)> _newMessageListeners = [];

  void connect(String uid) {
    if (uid.isEmpty) {
      disconnect();
      return;
    }
    if (_boundUid == uid && _socket != null) return;

    try {
      _socket?.disconnect();
    } catch (_) {}

    _boundUid = uid;
    final origin = ApiConfig.socketOrigin;
    final s = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .build(),
    );

    s.onConnect((_) {
      s.emit('join_user', uid);
      for (final cid in _joinedConversations) {
        s.emit('join_conversation', cid);
      }
    });

    s.on('inbox_ping', (raw) => onInboxPing?.call(raw));
    s.on('new_message', _dispatchNewMessage);

    _socket = s;
  }

  void _dispatchNewMessage(dynamic data) {
    final copy = List<void Function(dynamic)>.from(_newMessageListeners);
    for (final h in copy) {
      h(data);
    }
  }

  /// Retourne une fonction pour désinscrire le listener.
  VoidCallback addNewMessageListener(void Function(dynamic) handler) {
    _newMessageListeners.add(handler);
    return () => _newMessageListeners.remove(handler);
  }

  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    final added = _joinedConversations.add(conversationId);
    if (added) {
      _socket?.emit('join_conversation', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    if (!_joinedConversations.remove(conversationId)) return;
    _socket?.emit('leave_conversation', conversationId);
  }

  void disconnect() {
    try {
      _socket?.disconnect();
    } catch (_) {}
    _socket = null;
    _boundUid = null;
    _joinedConversations.clear();
  }

  void dispose() {
    _newMessageListeners.clear();
    disconnect();
  }
}

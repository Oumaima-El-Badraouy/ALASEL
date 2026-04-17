import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

/// Barre supérieure : accès boîte de réception + badge messages non lus.
class ShellMessagesBar extends ConsumerStatefulWidget {
  const ShellMessagesBar({super.key});

  @override
  ConsumerState<ShellMessagesBar> createState() => _ShellMessagesBarState();
}

class _ShellMessagesBarState extends ConsumerState<ShellMessagesBar> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 18), (_) {
      ref.invalidate(inboxUnreadTotalProvider);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxUnreadTotalProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0.5,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Image.asset(
                'assets/branding/logo_al_asel.png',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(height: 36, width: 36),
              ),
              const Spacer(),
              async.when(
                data: (n) => Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 99 ? '99+' : '$n'),
                  child: IconButton(
                    tooltip: 'Messages',
                    onPressed: () => context.push('/inbox'),
                    icon: const Icon(Icons.mark_chat_unread_outlined),
                  ),
                ),
                loading: () => IconButton(
                  tooltip: 'Messages',
                  onPressed: () => context.push('/inbox'),
                  icon: const Icon(Icons.mark_chat_unread_outlined),
                ),
                error: (_, __) => IconButton(
                  tooltip: 'Messages',
                  onPressed: () => context.push('/inbox'),
                  icon: const Icon(Icons.mark_chat_unread_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

/// En-tête : logo + titre discret + messages (badge).
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
      elevation: 3,
      shadowColor: AppColors.deepBlue.withValues(alpha: 0.15),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.parchment,
              AppColors.sand.withValues(alpha: 0.96),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.45), width: 1.2),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Image.asset(
                  'assets/branding/logo_al_asel.png',
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 40, width: 40),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'AL ASEL',
                        style: GoogleFonts.elMessiri(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepBlue,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Mediouna',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.terracotta.withValues(alpha: 0.95),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                async.when(
                  data: (n) => Badge(
                    isLabelVisible: n > 0,
                    backgroundColor: AppColors.terracotta,
                    textColor: AppColors.white,
                    label: Text(n > 99 ? '99+' : '$n', style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 11)),
                    child: Material(
                      color: AppColors.deepBlue.withValues(alpha: 0.08),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Messages',
                        onPressed: () => context.push('/inbox'),
                        icon: const Icon(Icons.mark_chat_unread_outlined, color: AppColors.deepBlue),
                      ),
                    ),
                  ),
                  loading: () => IconButton(
                    tooltip: 'Messages',
                    onPressed: () => context.push('/inbox'),
                    icon: const Icon(Icons.mark_chat_unread_outlined, color: AppColors.deepBlue),
                  ),
                  error: (_, __) => IconButton(
                    tooltip: 'Messages',
                    onPressed: () => context.push('/inbox'),
                    icon: const Icon(Icons.mark_chat_unread_outlined, color: AppColors.deepBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

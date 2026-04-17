import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_pattern_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _scheduled = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    if (auth.ready && !_scheduled) {
      _scheduled = true;
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (!context.mounted) return;
        final a = ref.read(authNotifierProvider);
        if (!a.isAuthenticated) {
          context.go('/auth/login');
        } else if (a.user?.role == 'client') {
          context.go('/client');
        } else {
          context.go('/artisan');
        }
      });
    }

    return Scaffold(
      body: MoroccanPatternBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/logo_al_asel.png',
                  width: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => SvgPicture.asset(
                    'assets/branding/logo.svg',
                    width: 160,
                    height: 160,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'AL ASEL',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.deepBlue,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Artisans de Confiance. Mediouna d’Abord.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 28),
                if (!auth.ready) const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

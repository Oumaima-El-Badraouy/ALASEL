import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_pattern_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _scheduled = false;

  Future<void> _navigateAfterSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final longDone = prefs.getBool('splash_long_shown') ?? false;
    final ms = longDone ? 900 : 1600;
    await Future.delayed(Duration(milliseconds: ms));
    if (!longDone) await prefs.setBool('splash_long_shown', true);
    if (!mounted) return;
    final a = ref.read(authNotifierProvider);
    if (!a.isAuthenticated) {
      context.go('/auth/login');
    } else if (a.user?.role == 'client') {
      context.go('/client');
    } else {
      context.go('/artisan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    if (auth.ready && !_scheduled) {
      _scheduled = true;
      _navigateAfterSplash();
    }

    return Scaffold(
      body: MoroccanPatternBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.white.withValues(alpha: 0.85),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/branding/logo_al_asel.png',
                      width: 280,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => SvgPicture.asset(
                        'assets/branding/logo.svg',
                        width: 140,
                        height: 140,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.appName,
                textAlign: TextAlign.center,
                style: GoogleFonts.elMessiri(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.deepBlue,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

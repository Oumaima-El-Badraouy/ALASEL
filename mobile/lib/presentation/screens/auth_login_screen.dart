import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../widgets/moroccan_card.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/moroccan_ui_kit.dart';

class AuthLoginScreen extends ConsumerStatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  ConsumerState<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<AuthLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool loading = false;
  String? err;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (p.getBool('al_asel_remember_login') == true) {
      setState(() {
        _rememberMe = true;
        _email.text = p.getString('al_asel_saved_email') ?? '';
        _password.text = p.getString('al_asel_saved_password') ?? '';
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _loginErrorMessage(Object e) {
    final s = e.toString();
    if (s.contains('Connection refused') ||
        s.contains('SocketException') ||
        s.contains('connection error') ||
        s.contains('Failed host lookup')) {
      return S.errApiUnreachable;
    }
    return s;
  }

  Future<void> _submit() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).login(
            _email.text.trim(),
            _password.text,
            rememberMe: _rememberMe,
          );
      final u = ref.read(authNotifierProvider).user;
      if (!mounted) return;
      if (u?.role == 'client') {
        context.go('/client');
      } else if (u?.role == 'artisan') {
        context.go('/artisan');
      }
    } catch (e) {
      setState(() => err = _loginErrorMessage(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          S.loginTitle,
          style: GoogleFonts.elMessiri(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: MoroccanPatternBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/branding/logo_al_asel.png',
                    height: 88,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => SvgPicture.asset(
                      'assets/branding/logo.svg',
                      height: 88,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const MoroccanGoldBand(width: 100),
                const SizedBox(height: 20),
                Text(
                  S.welcomeLogin,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.elMessiri(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  S.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                MoroccanCard(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: S.emailLabel,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      FormSpacing.betweenInputs,
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: S.passwordLabel,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _rememberMe,
                        onChanged: loading ? null : (v) => setState(() => _rememberMe = v ?? false),
                        title: Text(S.rememberLogin, style: GoogleFonts.cairo(fontSize: 14)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (err != null) ...[
                        const SizedBox(height: 12),
                        Text(err!, style: const TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text(S.loginButton, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/auth/register/client'),
                  child: Text(S.registerClient, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => context.push('/auth/register/artisan'),
                  child: Text(S.registerArtisan, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

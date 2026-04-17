import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_pattern_background.dart';

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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      loading = true;
      err = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).login(_email.text.trim(), _password.text);
      final u = ref.read(authNotifierProvider).user;
      if (!mounted) return;
      if (u?.role == 'client') {
        context.go('/client');
      } else if (u?.role == 'artisan') {
        context.go('/artisan');
      }
    } catch (e) {
      setState(() => err = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: MoroccanPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/branding/logo_al_asel.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: AppColors.terracotta)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: loading ? null : _submit,
                child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Se connecter'),
              ),
              TextButton(
                onPressed: () => context.push('/auth/register/client'),
                child: const Text('Créer un compte client'),
              ),
              TextButton(
                onPressed: () => context.push('/auth/register/artisan'),
                child: const Text('Créer un compte artisan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

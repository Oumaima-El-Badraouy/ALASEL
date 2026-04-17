import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      final demo = await ref.read(marketplaceRepositoryProvider).requestEmailVerificationCode();
      if (!mounted) return;
      if (demo != null && demo.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('رمز التجربة: $demo')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال الرمز إلى بريدك.')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final c = _code.text.trim();
    if (c.length < 4 || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(marketplaceRepositoryProvider).verifyEmailCode(c);
      await ref.read(authNotifierProvider.notifier).refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.emailVerifiedOk)));
      context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authNotifierProvider).user;
    return Scaffold(
      appBar: AppBar(title: Text(S.verifyEmailTitle)),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(S.verifyEmailHint, style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.4)),
            if (u != null && u.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(u.email, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
            if (u?.emailVerified == true) ...[
              const SizedBox(height: 16),
              const Text('✓ البريد مؤكد', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
            ],
            FormSpacing.betweenInputs,
            FilledButton.tonal(
              onPressed: _busy ? null : _request,
              child: Text(S.requestCodeBtn),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.codeLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _confirm,
              child: Text(S.confirmCodeBtn),
            ),
          ],
        ),
      ),
    );
  }
}

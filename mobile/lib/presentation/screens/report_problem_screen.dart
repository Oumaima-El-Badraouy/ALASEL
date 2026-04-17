import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  ConsumerState<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  final _text = TextEditingController();
  final _cat = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    _cat.dispose();
    super.dispose();
  }

  String _errMsg(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['error'] != null) return '${d['error']}';
      if (e.response?.statusCode == 401) return 'غير مصرّح — أعد تسجيل الدخول.';
      if (e.response?.statusCode == 404) return 'المسار غير موجود — حدّث الخادم.';
      return e.message ?? '$e';
    }
    return '$e';
  }

  Future<void> _submit() async {
    final t = _text.text.trim();
    if (t.length < 3 || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(marketplaceRepositoryProvider).submitReport(
            text: t,
            category: _cat.text.trim().isEmpty ? null : _cat.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.reportSent)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errMsg(e))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.reportProblem)),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(S.reportHint, style: TextStyle(color: AppColors.muted.withValues(alpha: 0.95), height: 1.4)),
            FormSpacing.betweenInputs,
            TextField(
              controller: _cat,
              decoration: InputDecoration(
                labelText: S.reportCategoryOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _text,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: S.reportDetails,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : Text(S.send),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';

/// رفع صورتي البطاقة (وجه / ظهر) كـ data URL.
class CinUploadSection extends ConsumerStatefulWidget {
  const CinUploadSection({super.key});

  @override
  ConsumerState<CinUploadSection> createState() => _CinUploadSectionState();
}

class _CinUploadSectionState extends ConsumerState<CinUploadSection> {
  bool _saving = false;

  Future<void> _pick(bool recto) async {
    final p = ImagePicker();
    final x = await p.pickImage(source: ImageSource.gallery, maxWidth: 2000, imageQuality: 82);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (bytes.length > 4 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(S.imageTooLarge4mb)),
        );
      }
      return;
    }
    final b64 = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$b64';
    setState(() => _saving = true);
    try {
      await ref.read(marketplaceRepositoryProvider).patchMe({
        if (recto) 'cinRectoUrl': dataUrl else 'cinVersoUrl': dataUrl,
      });
      await ref.read(authNotifierProvider.notifier).refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.cinSaved)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authNotifierProvider).user;
    final hasR = u?.cinRectoUrl != null && u!.cinRectoUrl!.isNotEmpty;
    final hasV = u?.cinVersoUrl != null && u!.cinVersoUrl!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.accountVerification, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pick(true),
                    icon: Icon(hasR ? Icons.check_circle_outline : Icons.upload_outlined),
                    label: Text(S.cinRecto),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pick(false),
                    icon: Icon(hasV ? Icons.check_circle_outline : Icons.upload_outlined),
                    label: Text(S.cinVerso),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/verify-email'),
              icon: const Icon(Icons.mark_email_read_outlined, size: 20, color: AppColors.deepBlue),
              label: Text(S.verifyEmailTitle, style: const TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

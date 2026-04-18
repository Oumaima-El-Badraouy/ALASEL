import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/network/dio_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../widgets/moroccan_pattern_background.dart';

class AuthRegisterClientScreen extends ConsumerStatefulWidget {
  const AuthRegisterClientScreen({super.key});

  @override
  ConsumerState<AuthRegisterClientScreen> createState() => _AuthRegisterClientScreenState();
}

class _AuthRegisterClientScreenState extends ConsumerState<AuthRegisterClientScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  bool mediouna = false;
  bool loading = false;
  String? _photoDataUrl;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      imageQuality: 82,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _submit() async {
    if (!mediouna) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errMediounaRequired)),
      );
      return;
    }
    final fn = _first.text.trim();
    final ln = _last.text.trim();
    final tel = _phone.text.trim();
    if (fn.isEmpty || ln.isEmpty || tel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errClientRequiredFields)),
      );
      return;
    }
    final loc = _location.text.trim();
    if (loc.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errLocationRequired)),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).registerClient(
            firstName: fn,
            lastName: ln,
            phone: tel,
            email: _email.text.trim(),
            password: _password.text,
            location: loc,
            isMediounaVerified: true,
            photoUrl: _photoDataUrl,
          );
      if (mounted) context.go('/client');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyDioError(e))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(S.registerClientTitle)),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.deepBlue.withValues(alpha: 0.12),
                  backgroundImage: _photoDataUrl != null ? MemoryImage(base64Decode(_photoDataUrl!.split(',').last)) : null,
                  child: _photoDataUrl == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.deepBlue)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.profilePhotoOptional,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _first,
              decoration: InputDecoration(
                labelText: '${S.fieldFirstName} *',
              ),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _last,
              decoration: InputDecoration(
                labelText: '${S.fieldLastName} *',
              ),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: S.emailLabel),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: S.fieldPasswordMin),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${S.fieldPhoneRequired} *',
                hintText: '+212600000000',
              ),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _location,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: S.fieldLocationRequired,
                hintText: S.fieldLocationHint,
              ),
            ),
            CheckboxListTile(
              value: mediouna,
              onChanged: (v) => setState(() => mediouna = v ?? false),
              title: const Text(S.mediounaConfirmLabel),
              activeColor: AppColors.deepBlue,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(S.registerSubmit),
            ),
          ],
        ),
      ),
    );
  }
}

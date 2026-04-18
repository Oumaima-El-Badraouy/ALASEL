import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/constants/moroccan_trades.dart';
import '../../core/l10n/strings.dart';
import '../../core/network/dio_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../widgets/moroccan_pattern_background.dart';

class AuthRegisterArtisanScreen extends ConsumerStatefulWidget {
  const AuthRegisterArtisanScreen({super.key});

  @override
  ConsumerState<AuthRegisterArtisanScreen> createState() => _AuthRegisterArtisanScreenState();
}

class _AuthRegisterArtisanScreenState extends ConsumerState<AuthRegisterArtisanScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _location = TextEditingController();
  bool mediouna = false;
  bool loading = false;
  String _tradeId = moroccanTrades.first.id;
  String? _photoDataUrl;
  String? _cinRectoDataUrl;
  String? _cinVersoDataUrl;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
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

  Future<void> _pickCin(bool recto) async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 82,
    );
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
    if (!mounted) return;
    setState(() {
      if (recto) {
        _cinRectoDataUrl = dataUrl;
      } else {
        _cinVersoDataUrl = dataUrl;
      }
    });
  }

  Future<void> _submit() async {
    if (!mediouna) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errMediounaRequired)),
      );
      return;
    }
    if (_desc.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errDescMin10)),
      );
      return;
    }
    if (_cinRectoDataUrl == null || _cinVersoDataUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(S.errCinBothRequired)),
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
      await ref.read(authNotifierProvider.notifier).registerArtisan(
            fullName: _name.text.trim(),
            domain: _tradeId,
            description: _desc.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            location: loc,
            isMediounaVerified: true,
            photoUrl: _photoDataUrl,
            cinRectoUrl: _cinRectoDataUrl!,
            cinVersoUrl: _cinVersoDataUrl!,
          );
      if (mounted) context.go('/artisan');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyDioError(e))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasR = _cinRectoDataUrl != null && _cinRectoDataUrl!.isNotEmpty;
    final hasV = _cinVersoDataUrl != null && _cinVersoDataUrl!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text(S.registerArtisanTitle)),
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
              S.profilePhotoRecommended,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: S.fieldFullNameRequired),
            ),
            FormSpacing.betweenInputs,
            DropdownButtonFormField<String>(
              value: _tradeId,
              decoration: const InputDecoration(labelText: S.fieldTraditionalTrade),
              items: [
                for (final t in moroccanTrades)
                  DropdownMenuItem(value: t.id, child: Text(t.labelAr)),
              ],
              onChanged: (v) => setState(() => _tradeId = v ?? moroccanTrades.first.id),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: S.fieldDescriptionArtisanRequired,
              ),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: S.fieldPhoneRequired),
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
            const SizedBox(height: 16),
            Text(
              S.cinRegisterSectionTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickCin(true),
                    icon: Icon(hasR ? Icons.check_circle_outline : Icons.upload_outlined),
                    label: const Text(S.cinRecto),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickCin(false),
                    icon: Icon(hasV ? Icons.check_circle_outline : Icons.upload_outlined),
                    label: const Text(S.cinVerso),
                  ),
                ),
              ],
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

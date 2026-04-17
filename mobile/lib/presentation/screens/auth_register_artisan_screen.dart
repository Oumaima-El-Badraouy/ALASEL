import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/moroccan_pattern_background.dart';

class AuthRegisterArtisanScreen extends ConsumerStatefulWidget {
  const AuthRegisterArtisanScreen({super.key});

  @override
  ConsumerState<AuthRegisterArtisanScreen> createState() => _AuthRegisterArtisanScreenState();
}

class _AuthRegisterArtisanScreenState extends ConsumerState<AuthRegisterArtisanScreen> {
  final _name = TextEditingController();
  final _domain = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool mediouna = false;
  bool loading = false;
  String? _photoDataUrl;

  @override
  void dispose() {
    _name.dispose();
    _domain.dispose();
    _desc.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
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
        const SnackBar(content: Text('Confirmez que vous habitez à Mediouna — obligatoire.')),
      );
      return;
    }
    if (_desc.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil artisan : décrivez votre activité (au moins 10 caractères).')),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).registerArtisan(
            fullName: _name.text.trim(),
            domain: _domain.text.trim(),
            description: _desc.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            isMediounaVerified: true,
            photoUrl: _photoDataUrl,
          );
      if (mounted) context.go('/artisan');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription artisan')),
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
              'Photo de profil (recommandée)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet (obligatoire)')),
            TextField(controller: _domain, decoration: const InputDecoration(labelText: 'Domaine (plombier, peintre…)')),
            TextField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description du profil (obligatoire, min. 10 caractères)',
              ),
            ),
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone (obligatoire)')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe (min 6)')),
            CheckboxListTile(
              value: mediouna,
              onChanged: (v) => setState(() => mediouna = v ?? false),
              title: const Text('Je confirme habiter à Mediouna'),
              activeColor: AppColors.deepBlue,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}

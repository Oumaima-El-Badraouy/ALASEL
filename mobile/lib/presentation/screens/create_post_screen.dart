import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, required this.postType});

  /// artisan_service | client_request
  final String postType;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _content = TextEditingController();
  final _cat = TextEditingController();
  String? _mediaDataUrl;
  bool loading = false;

  bool get isArtisanService =>
      widget.postType == 'artisan_service' || widget.postType == 'service';

  @override
  void dispose() {
    _content.dispose();
    _cat.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final p = ImagePicker();
    final x = await p.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() => _mediaDataUrl = 'data:image/jpeg;base64,$b64');
  }

  Future<void> _pickVideoFrame() async {
    final p = ImagePicker();
    final x = await p.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (x == null) return;
    setState(() {
      _mediaDataUrl = x.path;
    });
  }

  Future<void> _submit() async {
    if (_content.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      final apiType = isArtisanService ? 'artisan_service' : 'client_request';
      await ref.read(marketplaceRepositoryProvider).createPost(
            type: apiType,
            content: _content.text.trim(),
            category: _cat.text.trim(),
            media: _mediaDataUrl,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isArtisanService ? 'Nouveau service' : 'Nouvelle demande')),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              isArtisanService
                  ? 'Ajoutez une image ou une vidéo (aperçu) et décrivez votre prestation.'
                  : 'Décrivez votre besoin à Mediouna.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            FormSpacing.betweenInputs,
            TextField(controller: _cat, decoration: const InputDecoration(labelText: 'Domaine / catégorie')),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickMedia,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Photo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickVideoFrame,
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Vidéo (chemin)'),
                ),
              ],
            ),
            if (_mediaDataUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _mediaDataUrl!.length > 80 ? '${_mediaDataUrl!.substring(0, 80)}…' : _mediaDataUrl!,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

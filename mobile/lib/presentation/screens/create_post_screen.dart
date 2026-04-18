import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';
import '../widgets/post_media_preview.dart';

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
  bool _videoUploading = false;

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
    final x = await p.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 45));
    if (x == null) return;
    final file = File(x.path);
    final len = await file.length();
    if (len > 12 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الفيديو كبير جداً (الحد ~12 ميغابايت).')),
        );
      }
      return;
    }
    setState(() => _videoUploading = true);
    try {
      final url = await ref.read(marketplaceRepositoryProvider).uploadPostVideo(
            file,
            filename: x.name,
          );
      if (!mounted) return;
      setState(() => _mediaDataUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _videoUploading = false);
    }
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
      if (!mounted) return;
      // Après `pop`, le shell (fil / onglets) est à nouveau abonné aux providers — sinon le tick
      // peut être ignoré tant que l’écran de création recouvre le reste.
      final container = ProviderScope.containerOf(context, listen: false);
      context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        container.read(feedSocketTickProvider.notifier).state++;
      });
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
      appBar: AppBar(title: Text(isArtisanService ? S.newServicePost : S.newRequestPost)),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              isArtisanService ? S.createPostServiceHint : S.createPostRequestHint,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 6,
              decoration: const InputDecoration(labelText: S.fieldDescription),
            ),
            FormSpacing.betweenInputs,
            TextField(controller: _cat, decoration: const InputDecoration(labelText: S.fieldDomainCategory)),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: loading || _videoUploading ? null : _pickMedia,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(S.btnPhoto),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: loading || _videoUploading ? null : _pickVideoFrame,
                  icon: _videoUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.videocam_outlined),
                  label: Text(_videoUploading ? 'جاري الرفع…' : 'فيديو'),
                ),
              ],
            ),
            if (_mediaDataUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PostMediaPreview(media: _mediaDataUrl!, aspectRatio: 16 / 9),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: loading ? null : _submit,
              child: loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text(S.publish),
            ),
          ],
        ),
      ),
    );
  }
}

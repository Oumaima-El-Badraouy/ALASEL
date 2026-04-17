import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
import '../../data/models/user_model.dart';
import '../providers/app_providers.dart';
import '../widgets/cin_upload_section.dart';
import '../widgets/moroccan_pattern_background.dart';

/// Nombre de demandes clients (posts `client_request`) visibles pour les artisans.
final _clientDemandsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(feedSocketTickProvider);
  final list = await ref.watch(marketplaceRepositoryProvider).postsFeed(postType: 'client_request');
  return list.length;
});

final _followersProv = FutureProvider.autoDispose.family<int, String>((ref, artisanId) async {
  return ref.watch(marketplaceRepositoryProvider).followersCount(artisanId);
});

class ArtisanProfileTabScreen extends ConsumerStatefulWidget {
  const ArtisanProfileTabScreen({super.key});

  @override
  ConsumerState<ArtisanProfileTabScreen> createState() => _ArtisanProfileTabScreenState();
}

class _ArtisanProfileTabScreenState extends ConsumerState<ArtisanProfileTabScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _domain = TextEditingController();
  final _description = TextEditingController();
  bool loading = true;
  bool saving = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _domain.dispose();
    _description.dispose();
    super.dispose();
  }

  void _applyUserToFields(UserModel u) {
    _firstName.text = u.firstName ?? '';
    _lastName.text = u.lastName ?? '';
    if (_firstName.text.isEmpty && _lastName.text.isEmpty && (u.name ?? '').trim().isNotEmpty) {
      final parts = u.name!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        _firstName.text = parts.first;
        _lastName.text = parts.sublist(1).join(' ');
      } else {
        _firstName.text = u.name!;
      }
    }
    _phone.text = u.phone ?? '';
    _domain.text = u.domain ?? '';
    _description.text = u.description ?? '';
  }

  Future<void> _load() async {
    final u = await ref.read(marketplaceRepositoryProvider).me();
    if (!mounted) return;
    _applyUserToFields(u);
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _pickPhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 88);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final b64 = base64Encode(bytes);
      final url = 'data:image/jpeg;base64,$b64';
      await ref.read(marketplaceRepositoryProvider).patchMe({'photoUrl': url});
      await ref.read(authNotifierProvider.notifier).refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.photoProfileUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await ref.read(marketplaceRepositoryProvider).patchMe({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'domain': _domain.text.trim(),
        'description': _description.text.trim(),
      });
      await ref.read(authNotifierProvider.notifier).refreshMe();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.profileUpdatedSnack)));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _avatar(UserModel? u, double radius) {
    if (u == null) {
      return CircleAvatar(radius: radius, backgroundColor: AppColors.deepBlue.withValues(alpha: 0.15));
    }
    final p = u.photoUrl;
    if (p != null && p.isNotEmpty) {
      if (p.startsWith('data:image')) {
        try {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(base64Decode(p.split(',').last)),
          );
        } catch (_) {}
      }
      if (p.startsWith('http://') || p.startsWith('https://')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.sandDeep,
          backgroundImage: CachedNetworkImageProvider(p),
        );
      }
    }
    final label = _initials(u);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.deepBlue.withValues(alpha: 0.15),
      child: Text(
        label,
        style: TextStyle(fontSize: radius * 0.65, fontWeight: FontWeight.w800, color: AppColors.deepBlue),
      ),
    );
  }

  String _initials(UserModel u) {
    final a = (_firstName.text.isNotEmpty ? _firstName.text : (u.firstName ?? u.name ?? '')).trim();
    final b = (_lastName.text.isNotEmpty ? _lastName.text : (u.lastName ?? '')).trim();
    if (a.isNotEmpty && b.isNotEmpty) return '${a[0]}${b[0]}'.toUpperCase();
    if (a.length >= 2) return a.substring(0, 2).toUpperCase();
    if (a.isNotEmpty) return a[0].toUpperCase();
    if (u.email.isNotEmpty) return u.email[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final u = auth.user;
    final uid = u?.id;
    final followersAsync = uid != null ? ref.watch(_followersProv(uid)) : const AsyncValue<int>.data(0);
    final demandsAsync = ref.watch(_clientDemandsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.artisanMyProfileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      body: MoroccanPatternBackground(
        child: loading || u == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_firstName, _lastName]),
                      builder: (context, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _uploadingPhoto
                                ? CircleAvatar(
                                    radius: 52,
                                    backgroundColor: AppColors.sandDeep,
                                    child: const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _avatar(u, 52),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Material(
                                color: AppColors.deepBlue,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                  onPressed: _uploadingPhoto ? null : _pickPhoto,
                                  tooltip: S.changePhotoTooltip,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: Listenable.merge([_firstName, _lastName]),
                    builder: (context, _) {
                      final combined = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
                      return Text(
                        combined.isEmpty ? u.display : combined,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      followersAsync.when(
                        data: (n) => _StatChip(label: S.followersLabel, value: '$n'),
                        loading: () => _StatChip(label: S.followersLabel, value: '…'),
                        error: (_, __) => _StatChip(label: S.followersLabel, value: '—'),
                      ),
                      demandsAsync.when(
                        data: (n) => _StatChip(label: S.clientDemandsCountLabel, value: '$n'),
                        loading: () => _StatChip(label: S.clientDemandsCountLabel, value: '…'),
                        error: (_, __) => _StatChip(label: S.clientDemandsCountLabel, value: '—'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(S.coordinatesSection, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  _ReadOnlyRow(label: S.emailRowLabel, value: u.email.trim().isEmpty ? '—' : u.email),
                  const SizedBox(height: 4),
                  Text(
                    S.phoneVisibleHint,
                    style: TextStyle(fontSize: 12, color: AppColors.muted.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: S.phoneFieldLabel,
                      hintText: S.phoneFieldHint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(S.identitySection, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: S.fieldFirstName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  FormSpacing.betweenInputs,
                  TextField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: S.fieldLastName,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(S.activitySection, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _domain,
                    decoration: const InputDecoration(
                      labelText: S.fieldDomainsComma,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  FormSpacing.betweenInputs,
                  TextField(
                    controller: _description,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: S.fieldDescriptionLabel,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CinUploadSection(),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.deepBlue,
                    ),
                    child: saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text(S.saveProfileButton),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.85),
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

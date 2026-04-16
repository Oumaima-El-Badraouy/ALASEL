import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

class ArtisanHomeScreen extends ConsumerStatefulWidget {
  const ArtisanHomeScreen({super.key});

  @override
  ConsumerState<ArtisanHomeScreen> createState() => _ArtisanHomeScreenState();
}

class _ArtisanHomeScreenState extends ConsumerState<ArtisanHomeScreen> {
  bool ready = false;
  String? error;

  final _bio = TextEditingController();
  final _cats = TextEditingController(text: 'plumbing,painting');
  final _areas = TextEditingController(text: 'Casablanca,Rabat');

  @override
  void dispose() {
    _bio.dispose();
    _cats.dispose();
    _areas.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final repo = ref.read(artisanRepositoryProvider);
      await repo.bootstrap(role: 'artisan', displayName: 'Artisan Démo', city: 'Casablanca');
      setState(() {
        ready = true;
        error = null;
      });
    } catch (e) {
      setState(() {
        ready = false;
        error = '$e';
      });
    }
  }

  Future<void> _saveProfile() async {
    final repo = ref.read(artisanRepositoryProvider);
    final categories = _cats.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final areas = _areas.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await repo.upsertArtisanProfile(
      categories: categories,
      serviceAreas: areas,
      bio: _bio.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil enregistré')));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_init);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace artisan')),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (error != null)
              Card(
                color: AppColors.terracotta.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(error!, style: const TextStyle(color: AppColors.ink)),
                ),
              ),
            if (!ready && error == null) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (ready) ...[
              Text(
                'Profil public + Trust Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ce flux utilise DEMO_ARTISAN_UID (voir api_config) pour ne pas écraser le profil client.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(controller: _bio, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio')),
              const SizedBox(height: 12),
              TextField(
                controller: _cats,
                decoration: const InputDecoration(labelText: 'Métiers (virgules)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _areas,
                decoration: const InputDecoration(labelText: 'Zones (villes)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveProfile, child: const Text('Publier le profil')),
            ],
          ],
        ),
      ),
    );
  }
}

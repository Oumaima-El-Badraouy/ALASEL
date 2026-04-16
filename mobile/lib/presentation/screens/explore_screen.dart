import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/artisan_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_pattern_background.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String? category;
  String city = '';
  bool onlyAvail = false;

  static const categories = [
    'plumbing',
    'painting',
    'carpentry',
    'electricity',
    'tiling',
    'hvac',
  ];

  @override
  Widget build(BuildContext context) {
    final filters = {
      'category': category,
      'city': city.isEmpty ? null : city,
      'available': onlyAvail ? 'true' : null,
    };
    final async = ref.watch(artisanListProvider(filters));

    return Scaffold(
      appBar: AppBar(title: const Text('Explorer')),
      body: MoroccanPatternBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    FilterChip(
                      label: Text(c),
                      selected: category == c,
                      onSelected: (v) => setState(() => category = v ? c : null),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Ville (ex: Casablanca)'),
                onChanged: (v) => setState(() => city = v.trim()),
              ),
            ),
            SwitchListTile(
              title: const Text('Disponible seulement'),
              value: onlyAvail,
              onChanged: (v) => setState(() => onlyAvail = v),
            ),
            Expanded(
              child: async.when(
                data: (list) {
                  final items = list;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun artisan — lancez l’API en mode MEMORY_STORE et créez un profil démo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final a = items[i];
                      return _ArtisanTile(
                        artisan: a,
                        onTap: () => context.push('/artisan/${a.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtisanTile extends StatelessWidget {
  const _ArtisanTile({required this.artisan, required this.onTap});

  final ArtisanModel artisan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(artisan.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${artisan.categories.join(", ")} · ${artisan.serviceAreas.join(", ")}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${artisan.trustScore}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
            const Text('Trust', style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

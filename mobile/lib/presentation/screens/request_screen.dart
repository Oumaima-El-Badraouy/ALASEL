import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_app_bar.dart';
import '../widgets/moroccan_card.dart';
import '../widgets/moroccan_pattern_background.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  String category = 'plumbing';
  double? sqm;
  String urgency = 'normal';
  Map<String, dynamic>? estimate;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _loadEstimate() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    final e = await repo.estimate(category: category, sqm: sqm, urgency: urgency);
    setState(() => estimate = e);
  }

  Future<void> _submit() async {
    final repo = ref.read(marketplaceRepositoryProvider);
    await repo.createRequest(
      title: _title.text.trim(),
      category: category,
      description: _desc.text.trim(),
      city: _city.text.trim(),
      urgency: urgency,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande publiée')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoroccanAppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('طلب جديد', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.zellijGlaze)),
            const Text('Nouvelle demande'),
          ],
        ),
      ),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: const [
                DropdownMenuItem(value: 'plumbing', child: Text('Plomberie')),
                DropdownMenuItem(value: 'painting', child: Text('Peinture')),
                DropdownMenuItem(value: 'carpentry', child: Text('Menuiserie')),
                DropdownMenuItem(value: 'electricity', child: Text('Électricité')),
                DropdownMenuItem(value: 'tiling', child: Text('Carrelage')),
                DropdownMenuItem(value: 'hvac', child: Text('Climatisation')),
              ],
              onChanged: (v) => setState(() => category = v ?? 'plumbing'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Surface (m²) — optionnel'),
                    onChanged: (v) => setState(() => sqm = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: urgency,
                    decoration: const InputDecoration(labelText: 'Urgence'),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    ],
                    onChanged: (v) => setState(() => urgency = v ?? 'normal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadEstimate,
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Estimer le budget (MAD)'),
            ),
            if (estimate != null) ...[
              const SizedBox(height: 12),
              MoroccanCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${estimate!['min']} – ${estimate!['max']} ${estimate!['currency']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.deepBlue),
                    ),
                    const SizedBox(height: 6),
                    Text(estimate!['disclaimer'] as String? ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Publier la demande'),
            ),
          ],
        ),
      ),
    );
  }
}

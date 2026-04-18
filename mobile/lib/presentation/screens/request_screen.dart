import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/moroccan_trades.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/form_spacing.dart';
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
  String category = moroccanTrades.first.id;
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
    ref.read(feedSocketTickProvider.notifier).state++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.requestPublishedSnack)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MoroccanAppBar(
        title: Text(
          S.newRequestPost,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.zellijGlaze),
        ),
      ),
      body: MoroccanPatternBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: S.fieldTitle),
            ),
            FormSpacing.betweenInputs,
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: S.fieldCategory),
              items: [
                for (final t in moroccanTrades)
                  DropdownMenuItem(value: t.id, child: Text(t.labelAr)),
              ],
              onChanged: (v) => setState(() => category = v ?? moroccanTrades.first.id),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: S.fieldDescription),
            ),
            FormSpacing.betweenInputs,
            TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: S.fieldCity),
            ),
            FormSpacing.betweenInputs,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: S.fieldSurfaceOptional),
                    onChanged: (v) => setState(() => sqm = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: urgency,
                    decoration: const InputDecoration(labelText: S.fieldUrgency),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text(S.urgencyNormal)),
                      DropdownMenuItem(value: 'urgent', child: Text(S.urgencyUrgent)),
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
              label: const Text(S.estimateBudget),
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
              child: const Text(S.publishRequest),
            ),
          ],
        ),
      ),
    );
  }
}

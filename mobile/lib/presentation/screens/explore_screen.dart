import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/moroccan_trades.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/artisan_model.dart';
import '../providers/app_providers.dart';
import '../widgets/moroccan_app_bar.dart';
import '../widgets/moroccan_card.dart';
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

  /// Clé stable pour [artisanListProvider] (évite re-fetch permanent si l’objet Map changeait).
  String get _filterKey =>
      '${category ?? ''}|${city.replaceAll('|', ' ')}|${onlyAvail ? '1' : '0'}';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artisanListProvider(_filterKey));

    return Scaffold(
      appBar: MoroccanAppBar(
        title: Text(
          S.exploreSubtitle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.zellijGlaze),
        ),
      ),
      body: MoroccanPatternBackground(
        child: Positioned.fill(
          child: async.when(
            data: (list) => _buildScrollContent(context, list: list, loading: false, err: null),
            loading: () => _buildScrollContent(context, list: const [], loading: true, err: null),
            error: (e, _) => _buildScrollContent(context, list: const [], loading: false, err: e),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollContent(
    BuildContext context, {
    required List<ArtisanModel> list,
    required bool loading,
    required Object? err,
  }) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(S.filterAll, style: const TextStyle(fontSize: 13)),
                          selected: category == null,
                          onSelected: (_) => setState(() => category = null),
                          selectedColor: AppColors.terracotta.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.deepBlue,
                        ),
                      ),
                      for (final t in moroccanTrades)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: Text(t.labelAr, style: const TextStyle(fontSize: 12)),
                            selected: category == t.id,
                            onSelected: (v) => setState(() => category = v ? t.id : null),
                            selectedColor: AppColors.terracotta.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.deepBlue,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: S.cityHint,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => city = v.trim()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(S.availableOnly),
                  value: onlyAvail,
                  onChanged: (v) => setState(() => onlyAvail = v),
                ),
              ],
            ),
          ),
        ),
        if (loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          )
        else if (err != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${S.errorPrefix}$err', textAlign: TextAlign.center),
              ),
            ),
          )
        else if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  S.noArtisansHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final a = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ArtisanTile(
                      artisan: a,
                      onTap: () {
                        final id = a.id.trim().isNotEmpty ? a.id : '';
                        if (id.isEmpty) return;
                        context.push('/artisan-profile/$id');
                      },
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _ArtisanTile extends StatelessWidget {
  const _ArtisanTile({required this.artisan, required this.onTap});

  final ArtisanModel artisan;
  final VoidCallback onTap;

  String _catsLabel() {
    if (artisan.categories.isEmpty) return '';
    return artisan.categories.map((c) => S.categoryLabel(c)).join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final initials = artisan.displayName.trim().isNotEmpty ? artisan.displayName.trim()[0].toUpperCase() : '?';
    return MoroccanCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.35),
          child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
        ),
        title: Text(artisan.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_catsLabel()}${artisan.serviceAreas.isNotEmpty ? ' · ${artisan.serviceAreas.join(", ")}' : ''}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${artisan.trustScore}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deepBlue)),
            const Text('ثقة', style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

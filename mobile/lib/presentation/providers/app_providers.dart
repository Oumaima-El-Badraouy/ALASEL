import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../data/models/artisan_model.dart';
import '../../data/repositories/marketplace_repository.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository();
});

final artisanRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(demoUid: ApiConfig.demoArtisanUid);
});

final artisanListProvider =
    FutureProvider.autoDispose.family<List<ArtisanModel>, Map<String, String?>>((ref, filters) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return repo.listArtisans(
    category: filters['category'],
    city: filters['city'],
    available: filters['available'] == 'true' ? true : null,
  );
});

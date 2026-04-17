import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/config/api_config.dart';
import '../../data/models/artisan_model.dart';
import '../../data/repositories/marketplace_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(authNotifierProvider);
  final token = auth.token;
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ),
  );
});

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.watch(dioProvider));
});

/// Total des messages non lus (toutes conversations).
final inboxUnreadTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(marketplaceRepositoryProvider);
  final items = await repo.listConversations();
  var n = 0;
  for (final c in items) {
    n += (c['unreadCount'] as num?)?.toInt() ?? 0;
  }
  return n;
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

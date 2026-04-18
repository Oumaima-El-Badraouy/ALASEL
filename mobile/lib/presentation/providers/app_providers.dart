import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/config/api_config.dart';
import '../../data/models/artisan_model.dart';
import '../../data/repositories/marketplace_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  final auth = ref.watch(authNotifierProvider);
  final token = auth.token;
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      sendTimeout: const Duration(minutes: 3),
      receiveTimeout: const Duration(minutes: 3),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.watch(dioProvider));
});

/// Incrémenté par Socket.IO (`inbox_ping` nouveaux posts) pour rafraîchir les fils sans recharger l’app.
final feedSocketTickProvider = StateProvider<int>((ref) => 0);

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

/// État d’abonnement client → artisan (invalider après « suivre » dans les commentaires).
final artisanFollowStatusProvider = FutureProvider.autoDispose.family<bool, String>((ref, artisanId) async {
  if (artisanId.isEmpty) return false;
  return ref.watch(marketplaceRepositoryProvider).isFollowing(artisanId);
});

/// Clé stable `cat|city|avail` — évite les rechargements en boucle (Map recréée à chaque build).
/// Si un métier est choisi et la liste est vide, on recharge **sans** filtre métier pour tester l’UI.
final artisanListProvider =
    FutureProvider.autoDispose.family<List<ArtisanModel>, String>((ref, filterKey) async {
  ref.keepAlive();
  final parts = filterKey.split('|');
  final cat = parts.isEmpty || parts[0].isEmpty ? null : parts[0];
  final city = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;
  final onlyAvail = parts.length > 2 && parts[2] == '1';
  final repo = ref.watch(marketplaceRepositoryProvider);
  var list = await repo.listArtisans(
    category: cat,
    city: city,
    available: onlyAvail ? true : null,
  );
  if (list.isEmpty && cat != null) {
    list = await repo.listArtisans(
      category: null,
      city: city,
      available: onlyAvail ? true : null,
    );
  }
  return list;
});

import 'package:dio/dio.dart';

import '../models/artisan_model.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';

class MarketplaceRepository {
  MarketplaceRepository({ApiClient? client, String? demoUid})
      : _dio = (client ?? ApiClient(demoUid: demoUid)).dio;

  final Dio _dio;

  Future<UserModel?> bootstrap({
    required String role,
    String displayName = 'User',
    String city = '',
  }) async {
    final res = await _dio.post('/users/bootstrap', data: {
      'role': role,
      'displayName': displayName,
      'city': city,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel?> me() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ArtisanModel>> listArtisans({
    String? category,
    String? city,
    bool? available,
  }) async {
    final res = await _dio.get('/artisans', queryParameters: {
      if (category != null) 'category': category,
      if (city != null && city.isNotEmpty) 'city': city,
      if (available == true) 'available': 'true',
    });
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => ArtisanModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<ArtisanModel> getArtisan(String id) async {
    final res = await _dio.get('/artisans/$id');
    return ArtisanModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> estimate({
    required String category,
    double? sqm,
    String? urgency,
  }) async {
    final res = await _dio.get('/estimate', queryParameters: {
      'category': category,
      if (sqm != null) 'sqm': sqm,
      if (urgency != null) 'urgency': urgency,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> matchSuggestions(String category, {String? city}) async {
    final res = await _dio.get('/artisans/match', queryParameters: {
      'category': category,
      if (city != null) 'city': city,
    });
    return (res.data['suggestions'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> createRequest({
    required String title,
    required String category,
    String description = '',
    String city = '',
    String urgency = 'normal',
  }) async {
    await _dio.post('/requests', data: {
      'title': title,
      'category': category,
      'description': description,
      'city': city,
      'urgency': urgency,
    });
  }

  Future<List<ServiceRequestModel>> myRequests() async {
    final res = await _dio.get('/requests/mine');
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => ServiceRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> upsertArtisanProfile({
    required List<String> categories,
    required List<String> serviceAreas,
    String bio = '',
  }) async {
    await _dio.put('/artisans/profile', data: {
      'categories': categories,
      'serviceAreas': serviceAreas,
      'bio': bio,
    });
  }
}

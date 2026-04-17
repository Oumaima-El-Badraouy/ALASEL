import 'package:dio/dio.dart';

import '../models/artisan_model.dart';
import '../models/post_comment_model.dart';
import '../models/post_model.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';

class MarketplaceRepository {
  MarketplaceRepository(this._dio);

  final Dio _dio;

  Future<UserModel> me() async {
    final res = await _dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> patchMe(Map<String, dynamic> data) async {
    await _dio.patch('/users/me', data: data);
  }

  Future<List<PostModel>> postsFeed({
    String? category,
    String postType = 'all',
    String? sort,
  }) async {
    final res = await _dio.get('/posts/feed', queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
      'postType': postType,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    });
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<PostModel>> myPosts() async {
    final res = await _dio.get('/posts/mine');
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<List<PostModel>> favoritePosts() async {
    final res = await _dio.get('/users/me/favorite-posts');
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<Map<String, String>> peerContact(String peerId) async {
    final res = await _dio.get('/users/peer/$peerId/contact');
    final m = res.data as Map<String, dynamic>;
    return {
      'phone': m['phone'] as String? ?? '',
      'displayName': m['displayName'] as String? ?? '',
    };
  }

  Future<void> createPost({
    required String type,
    required String content,
    String category = '',
    String? media,
  }) async {
    await _dio.post('/posts', data: {
      'type': type,
      'content': content,
      'category': category,
      if (media != null && media.isNotEmpty) 'media': media,
    });
  }

  Future<void> deletePost(String id) async {
    await _dio.delete('/posts/$id');
  }

  Future<void> addPostFavorite(String postId) async {
    await _dio.post('/posts/$postId/favorite');
  }

  Future<void> removePostFavorite(String postId) async {
    await _dio.delete('/posts/$postId/favorite');
  }

  /// Retourne `{ liked: bool, likesCount: int }`.
  Future<Map<String, dynamic>> togglePostLike(String postId) async {
    final res = await _dio.post('/posts/$postId/like');
    return res.data as Map<String, dynamic>;
  }

  Future<List<PostCommentModel>> postComments(String postId) async {
    final res = await _dio.get('/posts/$postId/comments');
    final list = (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => PostCommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> addPostComment(String postId, String text) async {
    await _dio.post('/posts/$postId/comments', data: {'text': text});
  }

  /// Personnes qui ont aimé ce post (prénom, nom, rôle).
  Future<List<Map<String, dynamic>>> postLikers(String postId) async {
    final res = await _dio.get('/posts/$postId/likes');
    return (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> followArtisan(String followingId) async {
    await _dio.post('/follow/$followingId');
  }

  Future<void> unfollowArtisan(String followingId) async {
    await _dio.delete('/follow/$followingId');
  }

  Future<bool> isFollowing(String followingId) async {
    final res = await _dio.get('/follow/$followingId/status');
    return res.data['following'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> myFollowing() async {
    final res = await _dio.get('/users/me/following');
    return res.data as Map<String, dynamic>;
  }

  Future<int> followersCount(String artisanId) async {
    final res = await _dio.get('/artisans/$artisanId/followers-count');
    return (res.data['count'] as num?)?.toInt() ?? 0;
  }

  Future<String> openConversation(String peerId) async {
    final res = await _dio.post('/conversations', data: {'peerId': peerId});
    final m = res.data as Map<String, dynamic>;
    return m['id'] as String? ?? '';
  }

  Future<List<Map<String, dynamic>>> listMessages(String conversationId) async {
    final res = await _dio.get('/conversations/$conversationId/messages');
    return (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> sendMessage(
    String conversationId, {
    String? text,
    String? audioUrl,
  }) async {
    await _dio.post('/conversations/$conversationId/messages', data: {
      if (text != null && text.isNotEmpty) 'text': text,
      if (audioUrl != null && audioUrl.isNotEmpty) 'audioUrl': audioUrl,
    });
  }

  Future<List<Map<String, dynamic>>> listConversations() async {
    final res = await _dio.get('/conversations');
    return (res.data['items'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> markConversationRead(String conversationId) async {
    await _dio.post('/conversations/$conversationId/read');
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

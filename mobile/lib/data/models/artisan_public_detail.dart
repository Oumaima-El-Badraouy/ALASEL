import 'artisan_model.dart';
import 'post_model.dart';

class ArtisanPublicDetail {
  ArtisanPublicDetail({
    required this.profile,
    required this.phone,
    required this.photoUrl,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.description,
    this.location,
    required this.servicePostsCount,
    required this.demandsInTradeCount,
    required this.posts,
  });

  final ArtisanModel profile;
  final String phone;
  final String? photoUrl;
  final String? firstName;
  final String? lastName;
  final String fullName;
  final String description;
  final String? location;
  final int servicePostsCount;
  final int demandsInTradeCount;
  final List<PostModel> posts;

  factory ArtisanPublicDetail.fromJson(Map<String, dynamic> j) {
    final u = j['user'] as Map<String, dynamic>? ?? {};
    final st = j['stats'] as Map<String, dynamic>? ?? {};
    final posts = (j['posts'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ArtisanPublicDetail(
      profile: ArtisanModel.fromJson(j['profile'] as Map<String, dynamic>),
      phone: u['phone'] as String? ?? '',
      photoUrl: u['photoUrl'] as String?,
      firstName: u['firstName'] as String?,
      lastName: u['lastName'] as String?,
      fullName: u['name'] as String? ?? '',
      description: u['description'] as String? ?? '',
      location: u['location'] as String?,
      servicePostsCount: (st['servicePostsCount'] as num?)?.toInt() ?? 0,
      demandsInTradeCount: (st['demandsInTradeCount'] as num?)?.toInt() ?? 0,
      posts: posts,
    );
  }
}

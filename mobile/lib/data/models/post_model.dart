/// Post — type: artisan_service | client_request (+ legacy service/demand)
class PostModel {
  PostModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.content,
    this.media,
    this.category,
    this.city,
    this.createdAt,
    this.authorId,
    this.postType,
    this.authorDisplayName,
    this.authorPhotoUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String userId;
  final String type;
  final String content;
  final String? media;
  final String? category;
  final String? city;
  final String? createdAt;
  final String? authorId;
  final String? postType;
  /// Renseigné par l’API sur le feed (nom artisan).
  final String? authorDisplayName;
  /// Photo de profil de l’auteur (`users.photoUrl`), renseignée par l’API.
  final String? authorPhotoUrl;
  final int likesCount;
  final int commentsCount;
  final bool likedByMe;

  bool get isService => type == 'artisan_service' || postType == 'service';
  bool get isDemand => type == 'client_request' || postType == 'demand';

  factory PostModel.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String? ??
        (j['postType'] == 'service' ? 'artisan_service' : j['postType'] == 'demand' ? 'client_request' : '');
    final uid = j['userId'] as String? ?? j['authorId'] as String? ?? '';
    final content = j['content'] as String? ??
        '${j['title'] ?? ''}\n${j['body'] ?? ''}'.trim();
    return PostModel(
      id: j['id'] as String? ?? '',
      userId: uid,
      type: type.isNotEmpty ? type : 'client_request',
      content: content,
      media: j['media'] as String?,
      category: j['category'] as String?,
      city: j['city'] as String?,
      createdAt: j['createdAt'] as String?,
      authorId: j['authorId'] as String?,
      postType: j['postType'] as String?,
      authorDisplayName: j['authorDisplayName'] as String?,
      authorPhotoUrl: j['authorPhotoUrl'] as String?,
      likesCount: (j['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (j['commentsCount'] as num?)?.toInt() ?? 0,
      likedByMe: j['likedByMe'] as bool? ?? false,
    );
  }
}

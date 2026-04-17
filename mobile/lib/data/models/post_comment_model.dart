class PostCommentModel {
  PostCommentModel({
    required this.id,
    required this.userId,
    required this.text,
    this.createdAt,
    this.authorDisplayName,
    this.authorFirstName,
    this.authorLastName,
    this.authorRole,
    this.authorPhotoUrl,
  });

  final String id;
  final String userId;
  final String text;
  final String? createdAt;
  final String? authorDisplayName;
  final String? authorFirstName;
  final String? authorLastName;
  /// `client` | `artisan`
  final String? authorRole;
  final String? authorPhotoUrl;

  String get displayNameLine {
    final fn = (authorFirstName ?? '').trim();
    final ln = (authorLastName ?? '').trim();
    if (fn.isNotEmpty || ln.isNotEmpty) {
      return '$fn $ln'.trim();
    }
    return authorDisplayName ?? 'Utilisateur';
  }

  factory PostCommentModel.fromJson(Map<String, dynamic> j) {
    return PostCommentModel(
      id: j['id'] as String? ?? '',
      userId: j['userId'] as String? ?? '',
      text: j['text'] as String? ?? '',
      createdAt: j['createdAt'] as String?,
      authorDisplayName: j['authorDisplayName'] as String?,
      authorFirstName: j['authorFirstName'] as String?,
      authorLastName: j['authorLastName'] as String?,
      authorRole: j['authorRole'] as String?,
      authorPhotoUrl: j['authorPhotoUrl'] as String?,
    );
  }
}

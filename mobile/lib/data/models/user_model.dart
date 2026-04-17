/// Aligné API — User (Mediouna only)
class UserModel {
  UserModel({
    required this.id,
    required this.role,
    required this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.phone,
    this.domain,
    this.description,
    this.isMediounaVerified,
    this.city,
    this.photoUrl,
    this.displayName,
    this.popularityScore,
    this.favoritePostIds = const [],
    this.emailVerified,
    this.cinRectoUrl,
    this.cinVersoUrl,
  });

  final String id;
  final String role;
  final String email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? domain;
  final String? description;
  final bool? isMediounaVerified;
  final String? city;
  final String? photoUrl;
  final String? displayName;
  final int? popularityScore;
  final List<String> favoritePostIds;
  final bool? emailVerified;
  final String? cinRectoUrl;
  final String? cinVersoUrl;

  String get display => name ?? displayName ?? '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['id'] as String? ?? '',
      role: j['role'] as String? ?? 'client',
      email: j['email'] as String? ?? '',
      name: j['name'] as String?,
      firstName: j['firstName'] as String?,
      lastName: j['lastName'] as String?,
      phone: j['phone'] as String?,
      domain: j['domain'] as String?,
      description: j['description'] as String? ?? j['bio'] as String?,
      isMediounaVerified: j['isMediounaVerified'] as bool? ?? j['mediounaResident'] as bool?,
      city: j['city'] as String?,
      photoUrl: j['photoUrl'] as String?,
      displayName: j['displayName'] as String?,
      popularityScore: (j['popularityScore'] as num?)?.toInt(),
      favoritePostIds: (j['favoritePostIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      emailVerified: j['emailVerified'] as bool?,
      cinRectoUrl: j['cinRectoUrl'] as String?,
      cinVersoUrl: j['cinVersoUrl'] as String?,
    );
  }
}

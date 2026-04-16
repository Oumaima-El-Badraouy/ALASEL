class UserModel {
  UserModel({
    required this.id,
    required this.role,
    required this.displayName,
    this.phone,
    this.city,
    this.photoUrl,
  });

  final String id;
  final String role;
  final String displayName;
  final String? phone;
  final String? city;
  final String? photoUrl;

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['id'] as String? ?? '',
      role: j['role'] as String? ?? 'client',
      displayName: j['displayName'] as String? ?? '',
      phone: j['phone'] as String?,
      city: j['city'] as String?,
      photoUrl: j['photoUrl'] as String?,
    );
  }
}

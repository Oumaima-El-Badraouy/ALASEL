class ServiceRequestModel {
  ServiceRequestModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    this.description,
    this.city,
    this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final String? description;
  final String? city;
  final String? createdAt;

  factory ServiceRequestModel.fromJson(Map<String, dynamic> j) {
    return ServiceRequestModel(
      id: j['id'] as String? ?? '',
      title: j['title'] as String? ?? '',
      category: j['category'] as String? ?? '',
      status: j['status'] as String? ?? 'open',
      description: j['description'] as String?,
      city: j['city'] as String?,
      createdAt: j['createdAt'] as String?,
    );
  }
}

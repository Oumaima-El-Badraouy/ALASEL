class PortfolioItem {
  PortfolioItem({
    required this.id,
    required this.type,
    this.beforeUrl,
    this.afterUrl,
    this.caption,
    this.videoUrl,
  });

  final String id;
  final String type;
  final String? beforeUrl;
  final String? afterUrl;
  final String? caption;
  final String? videoUrl;

  factory PortfolioItem.fromJson(Map<String, dynamic> j) {
    return PortfolioItem(
      id: j['id'] as String? ?? '',
      type: j['type'] as String? ?? 'image',
      beforeUrl: j['beforeUrl'] as String?,
      afterUrl: j['afterUrl'] as String?,
      caption: j['caption'] as String?,
      videoUrl: j['videoUrl'] as String?,
    );
  }
}

class ArtisanModel {
  ArtisanModel({
    required this.id,
    required this.displayName,
    required this.categories,
    required this.serviceAreas,
    required this.trustScore,
    this.bio,
    this.avgRating,
    this.reviewCount,
    this.available = true,
    this.portfolio = const [],
  });

  final String id;
  final String displayName;
  final List<String> categories;
  final List<String> serviceAreas;
  final int trustScore;
  final String? bio;
  final double? avgRating;
  final int? reviewCount;
  final bool available;
  final List<PortfolioItem> portfolio;

  factory ArtisanModel.fromJson(Map<String, dynamic> j) {
    final pf = (j['portfolio'] as List<dynamic>? ?? [])
        .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return ArtisanModel(
      id: j['id'] as String? ?? '',
      displayName: j['displayName'] as String? ?? '',
      categories: (j['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      serviceAreas: (j['serviceAreas'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      trustScore: (j['trustScore'] as num?)?.toInt() ?? 0,
      bio: j['bio'] as String?,
      avgRating: (j['avgRating'] as num?)?.toDouble(),
      reviewCount: (j['reviewCount'] as num?)?.toInt(),
      available: j['available'] as bool? ?? true,
      portfolio: pf,
    );
  }
}

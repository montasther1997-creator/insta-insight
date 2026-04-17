class ReportModel {
  final String id;
  final String userId;
  final double engagementRate;
  final int followersGrowth;
  final String? bestPostId;
  final String? worstPostId;
  final String? geminiSummary;
  final Map<String, dynamic>? geoBreakdown;
  final Map<String, dynamic>? postingHeatmap;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.userId,
    this.engagementRate = 0.0,
    this.followersGrowth = 0,
    this.bestPostId,
    this.worstPostId,
    this.geminiSummary,
    this.geoBreakdown,
    this.postingHeatmap,
    required this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
      followersGrowth: json['followers_growth'] as int? ?? 0,
      bestPostId: json['best_post_id'] as String?,
      worstPostId: json['worst_post_id'] as String?,
      geminiSummary: json['gemini_summary'] as String?,
      geoBreakdown: json['geo_breakdown'] as Map<String, dynamic>?,
      postingHeatmap: json['posting_heatmap'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'engagement_rate': engagementRate,
      'followers_growth': followersGrowth,
      'best_post_id': bestPostId,
      'worst_post_id': worstPostId,
      'gemini_summary': geminiSummary,
      'geo_breakdown': geoBreakdown,
      'posting_heatmap': postingHeatmap,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get geo data as a list of country entries
  List<GeoEntry> get geoEntries {
    if (geoBreakdown == null) return [];
    return geoBreakdown!.entries.map((e) {
      final data = e.value as Map<String, dynamic>;
      return GeoEntry(
        country: e.key,
        percentage: (data['percentage'] as num?)?.toDouble() ?? 0,
        engagementRate: (data['engagement_rate'] as num?)?.toDouble() ?? 0,
        bestTime: data['best_time'] as String? ?? '',
      );
    }).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
  }
}

class GeoEntry {
  final String country;
  final double percentage;
  final double engagementRate;
  final String bestTime;

  GeoEntry({
    required this.country,
    required this.percentage,
    required this.engagementRate,
    required this.bestTime,
  });
}

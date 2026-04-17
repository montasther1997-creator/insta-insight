class SuggestionModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String reason;
  final String priority; // high, medium, low
  final DateTime createdAt;

  SuggestionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.reason,
    required this.priority,
    required this.createdAt,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'reason': reason,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TrendingAudio {
  final String id;
  final String audioName;
  final String artistName;
  final int usageCount;
  final double growthRate;
  final List<String> countryCodes;
  final bool isRising;
  final DateTime detectedAt;

  TrendingAudio({
    required this.id,
    required this.audioName,
    required this.artistName,
    this.usageCount = 0,
    this.growthRate = 0.0,
    this.countryCodes = const [],
    this.isRising = false,
    required this.detectedAt,
  });

  factory TrendingAudio.fromJson(Map<String, dynamic> json) {
    return TrendingAudio(
      id: json['id'] as String,
      audioName: json['audio_name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      usageCount: json['usage_count'] as int? ?? 0,
      growthRate: (json['growth_rate'] as num?)?.toDouble() ?? 0.0,
      countryCodes: (json['country_codes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isRising: json['is_rising'] as bool? ?? false,
      detectedAt: DateTime.parse(json['detected_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audio_name': audioName,
      'artist_name': artistName,
      'usage_count': usageCount,
      'growth_rate': growthRate,
      'country_codes': countryCodes,
      'is_rising': isRising,
      'detected_at': detectedAt.toIso8601String(),
    };
  }
}

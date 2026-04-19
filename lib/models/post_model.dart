class PostModel {
  final String id;
  final String userId;
  final String postId;
  final String mediaType;
  final String thumbnailUrl;
  final String mediaUrl;
  final String caption;
  final String permalink;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final double engagementRate;
  final DateTime? postedAt;
  final String? geminiAnalysis;
  final DateTime analyzedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.mediaType,
    required this.thumbnailUrl,
    this.mediaUrl = '',
    this.caption = '',
    this.permalink = '',
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.engagementRate = 0.0,
    this.postedAt,
    this.geminiAnalysis,
    required this.analyzedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      postId: json['post_id'] as String,
      mediaType: json['media_type'] as String? ?? 'IMAGE',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      mediaUrl: json['media_url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      permalink: json['permalink'] as String? ?? '',
      viewsCount: json['views_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      savesCount: json['saves_count'] as int? ?? 0,
      engagementRate: (json['engagement_rate'] as num?)?.toDouble() ?? 0.0,
      postedAt: json['posted_at'] != null
          ? DateTime.parse(json['posted_at'] as String)
          : null,
      geminiAnalysis: json['gemini_analysis'] as String?,
      analyzedAt: DateTime.parse(json['analyzed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'media_type': mediaType,
      'thumbnail_url': thumbnailUrl,
      'media_url': mediaUrl,
      'caption': caption,
      'permalink': permalink,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'saves_count': savesCount,
      'engagement_rate': engagementRate,
      'posted_at': postedAt?.toIso8601String(),
      'gemini_analysis': geminiAnalysis,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }

  int get totalEngagement => likesCount + commentsCount + sharesCount + savesCount;

  bool get isVideo => mediaType == 'VIDEO' || mediaType == 'REELS';

  /// Extract hashtags from the caption text (e.g. "#reels #viral" → ["reels", "viral"]).
  List<String> get hashtags {
    if (caption.isEmpty) return const [];
    final re = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true);
    return re.allMatches(caption).map((m) => m.group(1)!).toList();
  }

  /// Caption stripped of trailing hashtag blocks, for clean preview.
  String get captionPreview {
    if (caption.isEmpty) return '';
    final firstHashIdx = caption.indexOf(RegExp(r'\s#'));
    if (firstHashIdx == -1) return caption.trim();
    final cleaned = caption.substring(0, firstHashIdx).trim();
    return cleaned.isEmpty ? caption.trim() : cleaned;
  }
}

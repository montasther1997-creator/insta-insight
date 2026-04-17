class UserModel {
  final String id;
  final String instagramId;
  final String username;
  final String fullName;
  final String profilePictureUrl;
  final String accessToken;
  final DateTime? tokenExpiresAt;
  final int followersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.instagramId,
    required this.username,
    required this.fullName,
    required this.profilePictureUrl,
    required this.accessToken,
    this.tokenExpiresAt,
    this.followersCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      instagramId: json['instagram_id'] as String,
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      profilePictureUrl: json['profile_picture_url'] as String? ?? '',
      accessToken: json['access_token'] as String,
      tokenExpiresAt: json['token_expires_at'] != null
          ? DateTime.parse(json['token_expires_at'] as String)
          : null,
      followersCount: json['followers_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instagram_id': instagramId,
      'username': username,
      'full_name': fullName,
      'profile_picture_url': profilePictureUrl,
      'access_token': accessToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'followers_count': followersCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? instagramId,
    String? username,
    String? fullName,
    String? profilePictureUrl,
    String? accessToken,
    DateTime? tokenExpiresAt,
    int? followersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      instagramId: instagramId ?? this.instagramId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      accessToken: accessToken ?? this.accessToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      followersCount: followersCount ?? this.followersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

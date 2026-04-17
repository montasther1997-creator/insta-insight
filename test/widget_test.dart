import 'package:flutter_test/flutter_test.dart';
import 'package:insta_insight/models/user_model.dart';
import 'package:insta_insight/models/post_model.dart';
import 'package:insta_insight/models/suggestion_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates valid user', () {
      final json = {
        'id': 'test-id',
        'instagram_id': '123456',
        'username': 'testuser',
        'full_name': 'Test User',
        'profile_picture_url': 'https://example.com/pic.jpg',
        'access_token': 'token123',
        'token_expires_at': '2026-06-01T00:00:00.000Z',
        'followers_count': 5000,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'test-id');
      expect(user.instagramId, '123456');
      expect(user.username, 'testuser');
      expect(user.followersCount, 5000);
      expect(user.tokenExpiresAt, isNotNull);
    });

    test('toJson roundtrip preserves data', () {
      final json = {
        'id': 'test-id',
        'instagram_id': '123456',
        'username': 'testuser',
        'full_name': 'Test User',
        'profile_picture_url': '',
        'access_token': 'token',
        'token_expires_at': '2026-06-01T00:00:00.000Z',
        'followers_count': 1000,
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      final output = user.toJson();

      expect(output['username'], 'testuser');
      expect(output['followers_count'], 1000);
    });

    test('copyWith creates modified copy', () {
      final user = UserModel(
        id: '1',
        instagramId: '123',
        username: 'old',
        fullName: 'Old Name',
        profilePictureUrl: '',
        accessToken: 'token',
        followersCount: 100,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final updated = user.copyWith(username: 'new', followersCount: 200);

      expect(updated.username, 'new');
      expect(updated.followersCount, 200);
      expect(updated.id, '1'); // unchanged
    });
  });

  group('PostModel', () {
    test('fromJson creates valid post', () {
      final json = {
        'id': 'post-1',
        'user_id': 'user-1',
        'post_id': 'ig-123',
        'media_type': 'REELS',
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'views_count': 10000,
        'likes_count': 500,
        'comments_count': 50,
        'engagement_rate': 5.5,
        'posted_at': '2026-03-15T14:30:00.000Z',
        'analyzed_at': '2026-03-15T15:00:00.000Z',
      };

      final post = PostModel.fromJson(json);

      expect(post.mediaType, 'REELS');
      expect(post.viewsCount, 10000);
      expect(post.totalEngagement, 550);
      expect(post.isVideo, true);
    });

    test('isVideo detects VIDEO and REELS', () {
      final reels = PostModel(
        id: '1', userId: 'u1', postId: 'p1',
        mediaType: 'REELS', thumbnailUrl: '', analyzedAt: DateTime.now(),
      );
      final video = PostModel(
        id: '2', userId: 'u1', postId: 'p2',
        mediaType: 'VIDEO', thumbnailUrl: '', analyzedAt: DateTime.now(),
      );
      final image = PostModel(
        id: '3', userId: 'u1', postId: 'p3',
        mediaType: 'IMAGE', thumbnailUrl: '', analyzedAt: DateTime.now(),
      );

      expect(reels.isVideo, true);
      expect(video.isVideo, true);
      expect(image.isVideo, false);
    });

    test('totalEngagement sums likes and comments', () {
      final post = PostModel(
        id: '1', userId: 'u1', postId: 'p1',
        mediaType: 'IMAGE', thumbnailUrl: '',
        likesCount: 100, commentsCount: 25,
        analyzedAt: DateTime.now(),
      );

      expect(post.totalEngagement, 125);
    });

    test('handles null posted_at', () {
      final json = {
        'id': 'post-1',
        'user_id': 'user-1',
        'post_id': 'ig-123',
        'media_type': 'IMAGE',
        'thumbnail_url': '',
        'analyzed_at': '2026-03-15T15:00:00.000Z',
      };

      final post = PostModel.fromJson(json);
      expect(post.postedAt, isNull);
      expect(post.viewsCount, 0);
    });
  });

  group('TrendingAudio', () {
    test('fromJson creates valid audio', () {
      final json = {
        'id': 'audio-1',
        'audio_name': 'Test Song',
        'artist_name': 'Artist',
        'usage_count': 50000,
        'growth_rate': 25.5,
        'country_codes': ['SA', 'AE', 'EG'],
        'is_rising': true,
        'detected_at': '2026-04-01T00:00:00.000Z',
      };

      final audio = TrendingAudio.fromJson(json);

      expect(audio.audioName, 'Test Song');
      expect(audio.usageCount, 50000);
      expect(audio.growthRate, 25.5);
      expect(audio.countryCodes.length, 3);
      expect(audio.isRising, true);
    });

    test('toJson roundtrip preserves data', () {
      final audio = TrendingAudio(
        id: '1',
        audioName: 'Song',
        artistName: 'Artist',
        usageCount: 1000,
        growthRate: 10.0,
        countryCodes: ['SA'],
        isRising: true,
        detectedAt: DateTime(2026, 4, 1),
      );

      final json = audio.toJson();
      final restored = TrendingAudio.fromJson(json);

      expect(restored.audioName, 'Song');
      expect(restored.usageCount, 1000);
      expect(restored.countryCodes, ['SA']);
    });
  });

  group('SuggestionModel', () {
    test('fromJson creates valid suggestion', () {
      final json = {
        'id': 'sug-1',
        'user_id': 'user-1',
        'title': 'فكرة محتوى',
        'description': 'وصف الفكرة',
        'reason': 'سبب الاقتراح',
        'priority': 'high',
        'created_at': '2026-04-01T00:00:00.000Z',
      };

      final suggestion = SuggestionModel.fromJson(json);

      expect(suggestion.title, 'فكرة محتوى');
      expect(suggestion.priority, 'high');
    });

    test('handles null fields with defaults', () {
      final json = {
        'id': 'sug-1',
        'user_id': 'user-1',
        'created_at': '2026-04-01T00:00:00.000Z',
      };

      final suggestion = SuggestionModel.fromJson(json);

      expect(suggestion.title, '');
      expect(suggestion.description, '');
      expect(suggestion.priority, 'medium');
    });
  });
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../auth/domain/user_model.dart';
import '../domain/story_model.dart';

class StoriesRepository {
  final ApiClient apiClient;
  final SupabaseService? supabaseService;
  final AuthStorage? authStorage;

  StoriesRepository({
    required this.apiClient,
    this.supabaseService,
    this.authStorage,
  });

  bool get _shouldUseSupabase =>
      AppConfig.useSupabase && supabaseService != null && supabaseService!.isInitialized;

  Future<List<StoryGroup>> fetchStories() async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final list = await supabaseService!.fetchStories(currentUserId);
      final List<StoryGroup> groups = [];
      for (final item in list) {
        final story = StoryModel.fromJson(item);
        final user = story.user ??
            UserModel(
              id: story.userId,
              username: 'user_${story.userId}',
              displayName: 'User ${story.userId}',
            );
        final existingGroup =
            groups.where((g) => g.user.id == story.userId).firstOrNull;
        if (existingGroup != null) {
          existingGroup.stories.add(story);
        } else {
          groups.add(StoryGroup(user: user, stories: [story]));
        }
      }
      return groups;
    }

    final response = await apiClient.get('/stories');
    final List<dynamic> list = response is List
        ? response
        : (response['groups'] as List<dynamic>? ??
            response['stories'] as List<dynamic>? ??
            []);

    final List<StoryGroup> groups = [];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('stories') && item.containsKey('user')) {
          groups.add(StoryGroup.fromJson(item));
        } else {
          // If flat list of stories returned
          final story = StoryModel.fromJson(item);
          final user = story.user ??
              UserModel(
                id: story.userId,
                username: 'user_${story.userId}',
                displayName: 'User ${story.userId}',
              );
          final existingGroup =
              groups.where((g) => g.user.id == story.userId).firstOrNull;
          if (existingGroup != null) {
            existingGroup.stories.add(story);
          } else {
            groups.add(StoryGroup(user: user, stories: [story]));
          }
        }
      }
    }
    return groups;
  }

  Future<StoryModel> createImageStory({
    required File imageFile,
    String? caption,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final data = await supabaseService!.createStory(
        userId: currentUserId,
        type: 'image',
        file: imageFile,
        caption: caption,
      );
      return StoryModel.fromJson(data);
    }

    final fileName = imageFile.path.split('/').last;
    final detectedMime = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    String effectiveMime = detectedMime;
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      effectiveMime = 'image/jpeg';
    } else if (fileName.endsWith('.png')) {
      effectiveMime = 'image/png';
    }

    final formData = FormData.fromMap({
      'type': 'image',
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: MediaType.parse(effectiveMime),
      ),
    });

    final response = await apiClient.postMultipart(
      '/stories',
      formData: formData,
      onSendProgress: onProgress,
    );
    final data = (response is Map<String, dynamic> && response['story'] != null)
        ? response['story'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return StoryModel.fromJson(data);
  }

  Future<StoryModel> createTextStory({
    required String text,
    required String bgColor,
  }) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final data = await supabaseService!.createStory(
        userId: currentUserId,
        type: 'text',
        text: text,
        bgColor: bgColor,
      );
      return StoryModel.fromJson(data);
    }

    final response = await apiClient.post(
      '/stories',
      data: {
        'type': 'text',
        'text': text,
        'bg_color': bgColor,
      },
    );

    final data = (response is Map<String, dynamic> && response['story'] != null)
        ? response['story'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return StoryModel.fromJson(data);
  }

  Future<void> markStoryViewed(int storyId) async {
    try {
      if (_shouldUseSupabase) {
        final currentUserId = await authStorage?.getUserId() ?? 0;
        await supabaseService!.viewStory(storyId, currentUserId);
        return;
      }
      await apiClient.post('/stories/$storyId/view', data: {});
    } catch (_) {}
  }

  Future<List<StoryViewerModel>> getStoryViewers(int storyId) async {
    final response = await apiClient.get('/stories/$storyId/viewers');
    final List<dynamic> list = response is List
        ? response
        : (response['viewers'] as List<dynamic>? ?? []);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => StoryViewerModel.fromJson(e))
        .toList();
  }

  Future<void> deleteStory(int storyId) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      await supabaseService!.deleteStory(storyId, currentUserId);
      return;
    }
    await apiClient.delete('/stories/$storyId');
  }
}

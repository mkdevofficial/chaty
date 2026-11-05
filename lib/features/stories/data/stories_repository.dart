import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/network/api_client.dart';
import '../domain/story_model.dart';

class StoriesRepository {
  final ApiClient apiClient;

  StoriesRepository({required this.apiClient});

  Future<List<StoryGroup>> fetchStories() async {
    final response = await apiClient.get('/stories');
    final List<dynamic> list = response is List
        ? response
        : (response['stories'] as List<dynamic>? ?? []);

    final Map<int, List<StoryModel>> userStoryMap = {};

    for (final item in list) {
      final story = StoryModel.fromJson(item as Map<String, dynamic>);
      userStoryMap.putIfAbsent(story.userId, () => []).add(story);
    }

    final List<StoryGroup> groups = [];
    for (final entry in userStoryMap.entries) {
      if (entry.value.isNotEmpty) {
        final user = entry.value.first.user;
        if (user != null) {
          groups.add(
            StoryGroup(
              user: user,
              stories: entry.value,
            ),
          );
        }
      }
    }
    return groups;
  }

  Future<StoryModel> createImageStory({
    required File imageFile,
    String? caption,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    final formData = FormData.fromMap({
      'type': 'image',
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    });

    final response = await apiClient.postMultipart('/stories', formData: formData);
    final data = (response is Map<String, dynamic> && response['story'] != null)
        ? response['story'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return StoryModel.fromJson(data);
  }

  Future<StoryModel> createTextStory({
    required String text,
    required String bgColor,
  }) async {
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
      await apiClient.post('/stories/$storyId/view');
    } catch (_) {}
  }

  Future<List<StoryViewerModel>> getStoryViewers(int storyId) async {
    final response = await apiClient.get('/stories/$storyId/viewers');
    final List<dynamic> list = response is List
        ? response
        : (response['viewers'] as List<dynamic>? ?? []);
    return list.map((e) => StoryViewerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteStory(int storyId) async {
    await apiClient.delete('/stories/$storyId');
  }
}

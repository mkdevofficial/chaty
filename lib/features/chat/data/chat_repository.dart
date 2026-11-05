import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../domain/conversation_model.dart';
import '../domain/message_model.dart';

class ChatRepository {
  final ApiClient apiClient;
  final AppDatabase database;

  ChatRepository({
    required this.apiClient,
    required this.database,
  });

  // --- Conversations ---

  Future<List<ConversationModel>> getCachedConversations() async {
    return await database.getCachedConversations();
  }

  Future<List<ConversationModel>> fetchConversations() async {
    final response = await apiClient.get('/conversations');
    final List<dynamic> list = response is List
        ? response
        : (response['conversations'] as List<dynamic>? ?? []);

    final conversations =
        list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();

    // Cache to SQLite
    await database.saveConversations(conversations);
    return conversations;
  }

  Future<ConversationModel> getOrCreateConversation(int userId) async {
    final response = await apiClient.post(
      '/conversations',
      data: {'user_id': userId},
    );

    final data = (response is Map<String, dynamic> && response['conversation'] != null)
        ? response['conversation'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    final conv = ConversationModel.fromJson(data);
    await database.saveConversations([conv]);
    return conv;
  }

  // --- Messages ---

  Future<List<MessageModel>> getCachedMessages(int conversationId, {int limit = 50}) async {
    return await database.getCachedMessages(conversationId, limit: limit);
  }

  Future<List<MessageModel>> fetchMessages(
    int conversationId, {
    int? beforeMessageId,
    int limit = 30,
  }) async {
    final Map<String, dynamic> query = {'limit': limit};
    if (beforeMessageId != null) {
      query['before'] = beforeMessageId;
    }

    final response = await apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: query,
    );

    final List<dynamic> list = response is List
        ? response
        : (response['messages'] as List<dynamic>? ?? []);

    final messages =
        list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();

    // Save to local cache
    await database.saveMessages(messages);
    return messages;
  }

  Future<MessageModel> sendTextMessage({
    required int conversationId,
    required String text,
    required String clientId,
  }) async {
    final response = await apiClient.post(
      '/conversations/$conversationId/messages',
      data: {
        'type': 'text',
        'text': text,
        'client_id': clientId,
      },
    );

    final data = (response is Map<String, dynamic> && response['message'] != null)
        ? response['message'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    final message = MessageModel.fromJson(data);
    await database.saveSingleMessage(message);
    return message;
  }

  Future<MessageModel> sendStickerMessage({
    required int conversationId,
    required String pack,
    required String id,
    required String clientId,
  }) async {
    final response = await apiClient.post(
      '/conversations/$conversationId/messages',
      data: {
        'type': 'sticker',
        'sticker': {'pack': pack, 'id': id},
        'client_id': clientId,
      },
    );

    final data = (response is Map<String, dynamic> && response['message'] != null)
        ? response['message'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    final message = MessageModel.fromJson(data);
    await database.saveSingleMessage(message);
    return message;
  }

  Future<MessageModel> sendMediaMessage({
    required int conversationId,
    required File file,
    required String type, // 'image', 'audio', 'file'
    required String clientId,
    int? durationMs,
    String? caption,
    String? text,
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final detectedMime = lookupMimeType(file.path) ?? 'application/octet-stream';

    String effectiveMime = detectedMime;
    if (type == 'audio') {
      if (fileName.endsWith('.m4a') || fileName.endsWith('.mp4')) {
        effectiveMime = 'audio/mp4';
      } else if (fileName.endsWith('.aac')) {
        effectiveMime = 'audio/aac';
      }
    } else if (type == 'image') {
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        effectiveMime = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        effectiveMime = 'image/png';
      }
    }

    final finalCaption = caption ?? text;

    final formData = FormData.fromMap({
      'type': type,
      'client_id': clientId,
      if (durationMs != null && durationMs > 0) 'duration_ms': durationMs.toString(),
      if (finalCaption != null && finalCaption.isNotEmpty) 'caption': finalCaption,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(effectiveMime),
      ),
    });

    final response = await apiClient.postMultipart(
      '/conversations/$conversationId/messages',
      formData: formData,
      onSendProgress: onProgress,
    );

    final data = (response is Map<String, dynamic> && response['message'] != null)
        ? response['message'] as Map<String, dynamic>
        : response as Map<String, dynamic>;

    final message = MessageModel.fromJson(data);
    await database.saveSingleMessage(message);
    return message;
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await apiClient.post('/conversations/$conversationId/read');
    } catch (_) {}
  }

  Future<File> downloadFile(
    int fileId,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    return await apiClient.downloadFile(
      '/files/$fileId',
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/message_model.dart';
import 'conversations_provider.dart';

class ChatMessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final bool isOtherUserTyping;
  final String? error;

  const ChatMessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasMoreOlder = true,
    this.isOtherUserTyping = false,
    this.error,
  });

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? hasMoreOlder,
    bool? isOtherUserTyping,
    String? error,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
      error: error,
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final int conversationId;
  final ChatRepository repository;
  final Ref ref;
  StreamSubscription? _wsSubscription;
  Timer? _typingTimer;
  final _uuid = const Uuid();

  ChatMessagesNotifier({
    required this.conversationId,
    required this.repository,
    required this.ref,
  }) : super(const ChatMessagesState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load cached messages immediately
    final cached = await repository.getCachedMessages(conversationId);
    if (cached.isNotEmpty) {
      state = state.copyWith(messages: cached);
    }

    // 2. Fetch fresh messages from server
    await fetchLatest();

    // 3. Mark as read
    ref.read(conversationsProvider.notifier).markAsRead(conversationId);

    // 4. Listen to WebSocket events
    final ws = ref.read(webSocketServiceProvider);
    _wsSubscription = ws.events.listen((event) {
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    if (type == 'message.new' && event['message'] != null) {
      try {
        final message = MessageModel.fromJson(event['message'] as Map<String, dynamic>);
        if (message.conversationId == conversationId) {
          _onIncomingMessage(message);
          ref.read(conversationsProvider.notifier).markAsRead(conversationId);
        }
      } catch (_) {}
    } else if (type == 'message.status' && event['message_id'] != null) {
      final msgId = event['message_id'] is int
          ? event['message_id'] as int
          : int.tryParse(event['message_id'].toString());
      final statusStr = event['status'] as String?;
      if (msgId != null && statusStr != null) {
        final newStatus = MessageStatusExtension.fromString(statusStr);
        _updateMessageStatus(msgId, newStatus);
      }
    } else if (type == 'typing' && event['conversation_id'] != null) {
      final convId = event['conversation_id'] is int
          ? event['conversation_id'] as int
          : int.tryParse(event['conversation_id'].toString());

      if (convId == conversationId) {
        final currentUserId = ref.read(authProvider).user?.id;
        final senderId = event['user_id'] is int
            ? event['user_id'] as int
            : int.tryParse(event['user_id'].toString());

        if (senderId != currentUserId) {
          final isTyping = event['is_typing'] == true || event['is_typing'] == 1;
          _setTyping(isTyping);
        }
      }
    }
  }

  void _setTyping(bool isTyping) {
    _typingTimer?.cancel();
    if (isTyping) {
      state = state.copyWith(isOtherUserTyping: true);
      _typingTimer = Timer(const Duration(seconds: 4), () {
        state = state.copyWith(isOtherUserTyping: false);
      });
    } else {
      state = state.copyWith(isOtherUserTyping: false);
    }
  }

  void _onIncomingMessage(MessageModel message) {
    final list = List<MessageModel>.from(state.messages);

    // If it's an optimistic match by client_id
    if (message.clientId != null) {
      final optIndex = list.indexWhere((m) => m.clientId == message.clientId);
      if (optIndex != -1) {
        list[optIndex] = message;
        state = state.copyWith(messages: list);
        return;
      }
    }

    // Check if duplicate
    if (!list.any((m) => m.id == message.id)) {
      list.add(message);
      state = state.copyWith(messages: list);
    }
  }

  void _updateMessageStatus(int messageId, MessageStatus status) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(status: status);
        }
        return m;
      }).toList(),
    );
  }

  Future<void> fetchLatest() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fresh = await repository.fetchMessages(conversationId, limit: 30);
      state = state.copyWith(
        messages: fresh,
        isLoading: false,
        hasMoreOlder: fresh.length >= 30,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoadingOlder || !state.hasMoreOlder || state.messages.isEmpty) return;

    final oldestId = state.messages.first.id;
    if (oldestId <= 0) return; // pending message

    state = state.copyWith(isLoadingOlder: true);
    try {
      final older = await repository.fetchMessages(
        conversationId,
        beforeMessageId: oldestId,
        limit: 30,
      );

      final combined = [...older, ...state.messages];
      // deduplicate by id
      final seenIds = <int>{};
      final uniqueMessages = combined.where((m) => seenIds.add(m.id)).toList();

      state = state.copyWith(
        messages: uniqueMessages,
        isLoadingOlder: false,
        hasMoreOlder: older.length >= 30,
      );
    } catch (e) {
      state = state.copyWith(isLoadingOlder: false);
    }
  }

  // --- Optimistic Sending ---

  Future<void> sendText(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final currentUserId = ref.read(authProvider).user?.id ?? 0;
    final clientId = _uuid.v4();
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      clientId: clientId,
      type: 'text',
      text: cleanText,
      status: MessageStatus.pending,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    // 1. Add optimistically
    state = state.copyWith(messages: [...state.messages, optimisticMsg]);

    // 2. Send to backend
    try {
      final sentMsg = await repository.sendTextMessage(
        conversationId: conversationId,
        text: cleanText,
        clientId: clientId,
      );

      _replaceMessage(clientId, sentMsg);
    } catch (e) {
      _markMessageFailed(clientId);
    }
  }

  Future<void> sendSticker({required String pack, required String id}) async {
    final currentUserId = ref.read(authProvider).user?.id ?? 0;
    final clientId = _uuid.v4();
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      clientId: clientId,
      type: 'sticker',
      sticker: MessageSticker(pack: pack, id: id),
      status: MessageStatus.pending,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    state = state.copyWith(messages: [...state.messages, optimisticMsg]);

    try {
      final sentMsg = await repository.sendStickerMessage(
        conversationId: conversationId,
        pack: pack,
        id: id,
        clientId: clientId,
      );

      _replaceMessage(clientId, sentMsg);
    } catch (e) {
      _markMessageFailed(clientId);
    }
  }

  Future<void> sendMedia({
    required File file,
    required String type, // 'image', 'audio', 'file'
    String? text,
  }) async {
    final currentUserId = ref.read(authProvider).user?.id ?? 0;
    final clientId = _uuid.v4();
    final tempId = -DateTime.now().millisecondsSinceEpoch;

    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      clientId: clientId,
      type: type,
      text: text,
      localFilePath: file.path,
      status: MessageStatus.pending,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    state = state.copyWith(messages: [...state.messages, optimisticMsg]);

    try {
      final sentMsg = await repository.sendMediaMessage(
        conversationId: conversationId,
        file: file,
        type: type,
        clientId: clientId,
        text: text,
      );

      _replaceMessage(clientId, sentMsg.copyWith(localFilePath: file.path));
    } catch (e) {
      _markMessageFailed(clientId);
    }
  }

  Future<void> retryFailedMessage(MessageModel message) async {
    if (message.clientId == null) return;
    _updateMessageStatus(message.id, MessageStatus.pending);

    try {
      MessageModel sentMsg;
      if (message.isText && message.text != null) {
        sentMsg = await repository.sendTextMessage(
          conversationId: conversationId,
          text: message.text!,
          clientId: message.clientId!,
        );
      } else if (message.isSticker && message.sticker != null) {
        sentMsg = await repository.sendStickerMessage(
          conversationId: conversationId,
          pack: message.sticker!.pack,
          id: message.sticker!.id,
          clientId: message.clientId!,
        );
      } else if (message.localFilePath != null) {
        sentMsg = await repository.sendMediaMessage(
          conversationId: conversationId,
          file: File(message.localFilePath!),
          type: message.type,
          clientId: message.clientId!,
          text: message.text,
        );
      } else {
        return;
      }

      _replaceMessage(message.clientId!, sentMsg);
    } catch (e) {
      _markMessageFailed(message.clientId!);
    }
  }

  void _replaceMessage(String clientId, MessageModel serverMsg) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientId == clientId) {
          return serverMsg;
        }
        return m;
      }).toList(),
    );
  }

  void _markMessageFailed(String clientId) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientId == clientId) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList(),
    );
  }

  void sendTyping(bool isTyping) {
    ref.read(webSocketServiceProvider).sendTyping(
      conversationId: conversationId,
      isTyping: isTyping,
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    ChatMessagesState, int>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  return ChatMessagesNotifier(
    conversationId: conversationId,
    repository: repository,
    ref: ref,
  );
});

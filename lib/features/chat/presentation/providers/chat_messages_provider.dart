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
  StreamSubscription? _resyncSubscription;
  Timer? _typingTimer;
  Timer? _readDebounce;
  final _uuid = const Uuid();

  ChatMessagesNotifier({
    required this.conversationId,
    required this.repository,
    required this.ref,
  }) : super(const ChatMessagesState()) {
    _init();
  }

  void _init() {
    // 1. Listen to WebSocket events & reconnect resyncs immediately
    final ws = ref.read(webSocketServiceProvider);
    _resyncSubscription = ws.resyncStream.listen((_) {
      fetchLatest();
    });

    _wsSubscription = ws.events.listen((event) {
      _handleWsEvent(event);
    });

    // 2. Load cached messages and fetch fresh from server
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final cached = await repository.getCachedMessages(conversationId);
    if (cached.isNotEmpty) {
      state = state.copyWith(messages: cached);
    }

    await fetchLatest();

    ref.read(conversationsProvider.notifier).markAsRead(conversationId);
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final eventName = (event['event'] ?? event['type']) as String?;
    final eventData = (event['data'] is Map<String, dynamic>)
        ? event['data'] as Map<String, dynamic>
        : event;

    if (eventName == 'message.new') {
      try {
        final rawMsg = eventData['message'] ?? eventData;
        if (rawMsg is Map<String, dynamic>) {
          final message = MessageModel.fromJson(rawMsg);
          if (message.conversationId == conversationId) {
            _onIncomingMessage(message);
            _debounceMarkAsRead();
          }
        }
      } catch (_) {}
    } else if (eventName == 'message.status') {
      final statusStr = (eventData['status'] ?? event['status']) as String?;
      if (statusStr != null) {
        final newStatus = MessageStatusExtension.fromString(statusStr);
        final List<int> idsToUpdate = [];

        final rawIds = eventData['message_ids'] ?? event['message_ids'];
        if (rawIds is List) {
          for (final item in rawIds) {
            final id = item is int ? item : int.tryParse(item.toString());
            if (id != null) idsToUpdate.add(id);
          }
        }

        final singleId = eventData['message_id'] ?? event['message_id'];
        if (singleId != null) {
          final id = singleId is int ? singleId : int.tryParse(singleId.toString());
          if (id != null && !idsToUpdate.contains(id)) idsToUpdate.add(id);
        }

        if (idsToUpdate.isNotEmpty) {
          _updateMessageStatuses(idsToUpdate, newStatus);
        }
      }
    } else if (eventName == 'message.deleted') {
      final convIdRaw = eventData['conversation_id'] ?? event['conversation_id'];
      final convId =
          convIdRaw is int ? convIdRaw : int.tryParse(convIdRaw?.toString() ?? '');
      if (convId == conversationId || convId == null) {
        final msgIdRaw = eventData['message_id'] ?? event['message_id'];
        final msgId =
            msgIdRaw is int ? msgIdRaw : int.tryParse(msgIdRaw?.toString() ?? '');
        if (msgId != null) {
          _onMessageDeleted(msgId);
        }
      }
    } else if (eventName == 'typing') {
      final convIdRaw = eventData['conversation_id'] ?? event['conversation_id'];
      final convId =
          convIdRaw is int ? convIdRaw : int.tryParse(convIdRaw?.toString() ?? '');

      if (convId == conversationId) {
        final currentUserId = ref.read(authProvider).user?.id;
        final senderIdRaw = eventData['user_id'] ?? event['user_id'];
        final senderId =
            senderIdRaw is int ? senderIdRaw : int.tryParse(senderIdRaw?.toString() ?? '');

        if (senderId != currentUserId) {
          final isTyping = (eventData['is_typing'] ?? event['is_typing']) == true ||
              (eventData['is_typing'] ?? event['is_typing']) == 1;
          _setTyping(isTyping);
        }
      }
    }
  }

  void _debounceMarkAsRead() {
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 300), () {
      repository.markConversationAsRead(conversationId);
      ref.read(conversationsProvider.notifier).markAsRead(conversationId);
    });
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
        list[optIndex] = message.copyWith(localFilePath: list[optIndex].localFilePath);
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
    _updateMessageStatuses([messageId], status);
  }

  void _updateMessageStatuses(List<int> messageIds, MessageStatus status) {
    final idSet = messageIds.toSet();
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (idSet.contains(m.id)) {
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

  Future<void> sendText(
    String text, {
    int? replyToId,
    MessageReplyTo? replyTo,
  }) async {
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
      replyTo: replyTo,
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
        replyToId: replyToId,
      );

      _replaceMessage(clientId, sentMsg);
    } catch (e) {
      _markMessageFailed(clientId);
    }
  }

  Future<void> sendSticker({
    required String pack,
    required String id,
    int? replyToId,
    MessageReplyTo? replyTo,
  }) async {
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
      replyTo: replyTo,
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
        replyToId: replyToId,
      );

      _replaceMessage(clientId, sentMsg);
    } catch (e) {
      _markMessageFailed(clientId);
    }
  }

  Future<void> sendMedia({
    required File file,
    required String type, // 'image', 'audio', 'file'
    String? caption,
    String? text,
    int? durationMs,
    int? replyToId,
    MessageReplyTo? replyTo,
  }) async {
    final currentUserId = ref.read(authProvider).user?.id ?? 0;
    final clientId = _uuid.v4();
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final finalCaption = caption ?? text;

    final optimisticMsg = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      clientId: clientId,
      type: type,
      text: finalCaption,
      localFilePath: file.path,
      replyTo: replyTo,
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
        durationMs: durationMs,
        caption: finalCaption,
        replyToId: replyToId,
      );

      _replaceMessage(clientId, sentMsg.copyWith(localFilePath: file.path));
    } catch (e) {
      _markMessageFailed(clientId);
      rethrow;
    }
  }

  Future<void> deleteMessage(int messageId, String scope) async {
    if (scope == 'me') {
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != messageId).toList(),
      );
    } else {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(
              deleted: true,
              text: null,
              attachment: null,
              sticker: null,
            );
          }
          return m;
        }).toList(),
      );
    }

    await repository.deleteMessage(
      conversationId: conversationId,
      messageId: messageId,
      scope: scope,
    );
  }

  void _onMessageDeleted(int messageId) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(
            deleted: true,
            text: null,
            attachment: null,
            sticker: null,
          );
        }
        return m;
      }).toList(),
    );
  }

  Future<bool> loadOlderUntilFound(int targetMessageId) async {
    int attempts = 0;
    while (!state.messages.any((m) => m.id == targetMessageId) &&
        state.hasMoreOlder &&
        attempts < 5) {
      attempts++;
      await loadOlderMessages();
    }
    return state.messages.any((m) => m.id == targetMessageId);
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
    _resyncSubscription?.cancel();
    _typingTimer?.cancel();
    _readDebounce?.cancel();
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

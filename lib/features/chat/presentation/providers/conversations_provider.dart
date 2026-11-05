import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../../domain/conversation_model.dart';
import '../../domain/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final database = ref.watch(databaseProvider);
  return ChatRepository(apiClient: apiClient, database: database);
});

class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  int get totalUnreadCount =>
      conversations.fold(0, (sum, item) => sum + item.unreadCount);

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  final ChatRepository _repository;
  final Ref _ref;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _resyncSubscription;

  ConversationsNotifier(this._repository, this._ref)
      : super(const ConversationsState()) {
    _init();
  }

  void _init() {
    // 1. Listen to WebSocket resync stream and events immediately
    final ws = _ref.read(webSocketServiceProvider);
    _resyncSubscription = ws.resyncStream.listen((_) {
      refresh();
    });

    _wsSubscription = ws.events.listen((event) {
      _handleWsEvent(event);
    });

    // 2. Load cached conversations and fetch remote
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final cached = await _repository.getCachedConversations();
    if (cached.isNotEmpty) {
      state = state.copyWith(conversations: cached);
    }
    await refresh();
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
          _onNewMessage(message);
        }
      } catch (_) {}
    } else if (eventName == 'conversation.updated') {
      try {
        final convRaw = eventData['conversation'] ?? eventData;
        if (convRaw is Map<String, dynamic>) {
          final updatedConv = ConversationModel.fromJson(convRaw);
          _onConversationUpdated(updatedConv);
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
          _updateLastMessageStatus(idsToUpdate, newStatus);
        }
      }
    } else if (eventName == 'message.deleted') {
      final messageIdRaw = eventData['message_id'] ?? event['message_id'];
      final messageId =
          messageIdRaw is int ? messageIdRaw : int.tryParse(messageIdRaw?.toString() ?? '');
      if (messageId != null) {
        _onMessageDeleted(messageId);
      }
    } else if (eventName == 'presence') {
      final userIdRaw = eventData['user_id'] ?? event['user_id'];
      final userId =
          userIdRaw is int ? userIdRaw : int.tryParse(userIdRaw?.toString() ?? '');
      final isOnline = (eventData['online'] ?? event['online']) == true ||
          (eventData['online'] ?? event['online']) == 1;
      final lastSeen = (eventData['last_seen'] ?? event['last_seen']) as String?;

      if (userId != null) {
        state = state.copyWith(
          conversations: state.conversations.map((c) {
            if (c.peer.id == userId) {
              return c.copyWith(
                peer: c.peer.copyWith(
                  online: isOnline,
                  lastSeen: lastSeen,
                ),
              );
            }
            return c;
          }).toList(),
        );
      }
    }
  }

  void _onNewMessage(MessageModel message) {
    final list = List<ConversationModel>.from(state.conversations);
    final index = list.indexWhere((c) => c.id == message.conversationId);
    final activeId = _ref.read(activeConversationIdProvider);
    final currentUserId = _ref.read(authProvider).user?.id ?? 0;

    final isCurrentlyOpen = activeId == message.conversationId;

    if (index != -1) {
      final existing = list[index];
      final newUnread = isCurrentlyOpen
          ? 0
          : (message.senderId == currentUserId
              ? existing.unreadCount
              : existing.unreadCount + 1);

      final updated = existing.copyWith(
        lastMessage: message,
        unreadCount: newUnread,
        updatedAt: message.createdAt,
      );
      list.removeAt(index);
      list.insert(0, updated);
      state = state.copyWith(conversations: list);

      if (isCurrentlyOpen) {
        _repository.markConversationAsRead(message.conversationId);
      }
    } else {
      // New conversation initiated by other user -> refresh from server
      refresh();
    }
  }

  void _onConversationUpdated(ConversationModel serverConv) {
    final activeId = _ref.read(activeConversationIdProvider);
    final list = List<ConversationModel>.from(state.conversations);
    final index = list.indexWhere((c) => c.id == serverConv.id);

    // If chat is currently open, unread count should be 0
    final effectiveConv = (activeId == serverConv.id)
        ? serverConv.copyWith(unreadCount: 0)
        : serverConv;

    if (index != -1) {
      list[index] = effectiveConv;
    } else {
      list.insert(0, effectiveConv);
    }

    // Sort by updatedAt descending
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(conversations: list);
  }

  void _updateLastMessageStatus(List<int> ids, MessageStatus status) {
    final idSet = ids.toSet();
    state = state.copyWith(
      conversations: state.conversations.map((c) {
        if (c.lastMessage != null && idSet.contains(c.lastMessage!.id)) {
          return c.copyWith(
            lastMessage: c.lastMessage!.copyWith(status: status),
          );
        }
        return c;
      }).toList(),
    );
  }

  void _onMessageDeleted(int messageId) {
    state = state.copyWith(
      conversations: state.conversations.map((c) {
        if (c.lastMessage != null && c.lastMessage!.id == messageId) {
          return c.copyWith(
            lastMessage: c.lastMessage!.copyWith(
              deleted: true,
              text: null,
              attachment: null,
              sticker: null,
            ),
          );
        }
        return c;
      }).toList(),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final fresh = await _repository.fetchConversations();
      state = state.copyWith(conversations: fresh, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void markAsRead(int conversationId) {
    final list = state.conversations.map((c) {
      if (c.id == conversationId) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();
    state = state.copyWith(conversations: list);
    _repository.markConversationAsRead(conversationId);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _resyncSubscription?.cancel();
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ConversationsNotifier(repository, ref);
});

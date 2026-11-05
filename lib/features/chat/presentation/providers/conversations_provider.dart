import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
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

  ConversationsNotifier(this._repository, this._ref)
      : super(const ConversationsState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Load cached conversations immediately
    final cached = await _repository.getCachedConversations();
    if (cached.isNotEmpty) {
      state = state.copyWith(conversations: cached);
    }

    // 2. Refresh from server
    await refresh();

    // 3. Listen to WebSocket events
    final ws = _ref.read(webSocketServiceProvider);
    ws.onResyncNeeded = () {
      refresh();
    };

    _wsSubscription = ws.events.listen((event) {
      _handleWsEvent(event);
    });
  }

  void _handleWsEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;

    if (type == 'message.new' && event['message'] != null) {
      try {
        final message = MessageModel.fromJson(event['message'] as Map<String, dynamic>);
        _onNewMessage(message);
      } catch (_) {}
    } else if (type == 'presence' && event['user_id'] != null) {
      final userId = event['user_id'] is int
          ? event['user_id'] as int
          : int.tryParse(event['user_id'].toString());
      final isOnline = event['online'] == true || event['online'] == 1;
      final lastSeen = event['last_seen'] as String?;

      if (userId != null) {
        state = state.copyWith(
          conversations: state.conversations.map((c) {
            if (c.otherUser.id == userId) {
              return c.copyWith(
                otherUser: c.otherUser.copyWith(
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

    if (index != -1) {
      final existing = list[index];
      final updated = existing.copyWith(
        lastMessage: message,
        unreadCount: existing.unreadCount + 1,
        updatedAt: message.createdAt,
      );
      list.removeAt(index);
      list.insert(0, updated);
      state = state.copyWith(conversations: list);
    } else {
      // New conversation initiated by other user -> refresh
      refresh();
    }
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
    super.dispose();
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return ConversationsNotifier(repository, ref);
});

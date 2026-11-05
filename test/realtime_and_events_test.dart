import 'dart:async';
import 'package:chaty/core/network/websocket_service.dart';
import 'package:chaty/core/providers/core_providers.dart';
import 'package:chaty/core/storage/auth_storage.dart';
import 'package:chaty/features/auth/domain/user_model.dart';
import 'package:chaty/features/auth/presentation/auth_provider.dart';
import 'package:chaty/features/chat/data/chat_repository.dart';
import 'package:chaty/features/chat/domain/conversation_model.dart';
import 'package:chaty/features/chat/domain/message_model.dart';
import 'package:chaty/features/chat/presentation/providers/chat_messages_provider.dart';
import 'package:chaty/features/chat/presentation/providers/conversations_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthStorage implements AuthStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getToken() async => 'fake_token';
}

class FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  FakeAuthNotifier(UserModel user)
      : super(AuthState(status: AuthStatus.authenticated, user: user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebSocketService extends WebSocketService {
  final _testEventController = StreamController<Map<String, dynamic>>.broadcast();
  final _testResyncController = StreamController<void>.broadcast();

  FakeWebSocketService({required super.authStorage});

  @override
  Stream<Map<String, dynamic>> get events => _testEventController.stream;

  @override
  Stream<void> get resyncStream => _testResyncController.stream;

  void emitEvent(Map<String, dynamic> event) {
    _testEventController.add(event);
  }

  void emitResync() {
    _testResyncController.add(null);
  }

  @override
  void dispose() {
    _testEventController.close();
    _testResyncController.close();
    super.dispose();
  }
}

class FakeChatRepository implements ChatRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  List<ConversationModel> conversations = [];
  List<MessageModel> messages = [];
  int markReadCalledCount = 0;
  int? lastMarkedReadConvId;

  @override
  Future<List<ConversationModel>> getCachedConversations() async => conversations;

  @override
  Future<List<ConversationModel>> fetchConversations() async => conversations;

  @override
  Future<List<MessageModel>> getCachedMessages(int conversationId, {int limit = 50}) async =>
      messages.where((m) => m.conversationId == conversationId).toList();

  @override
  Future<List<MessageModel>> fetchMessages(int conversationId,
      {int? beforeMessageId, int limit = 30}) async =>
      messages.where((m) => m.conversationId == conversationId).toList();

  @override
  Future<void> markConversationAsRead(int conversationId) async {
    markReadCalledCount++;
    lastMarkedReadConvId = conversationId;
  }

  @override
  Future<void> deleteMessage({
    required int conversationId,
    required int messageId,
    required String scope,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeWebSocketService fakeWs;
  late FakeChatRepository fakeRepo;
  late ProviderContainer container;

  final testUser = const UserModel(
    id: 1,
    username: 'me',
    displayName: 'Me',
  );

  final peerUser = const UserModel(
    id: 2,
    username: 'peer',
    displayName: 'Peer User',
    online: false,
  );

  final initialConv = ConversationModel(
    id: 10,
    peer: peerUser,
    unreadCount: 2,
    updatedAt: '2026-11-05T08:00:00Z',
    lastMessage: MessageModel(
      id: 100,
      conversationId: 10,
      senderId: 2,
      type: 'text',
      text: 'Hey there',
      status: MessageStatus.sent,
      createdAt: '2026-11-05T08:00:00Z',
    ),
  );

  setUp(() {
    final fakeAuthStorage = FakeAuthStorage();
    fakeWs = FakeWebSocketService(authStorage: fakeAuthStorage);
    fakeRepo = FakeChatRepository();
    fakeRepo.conversations = [initialConv];
    fakeRepo.messages = [initialConv.lastMessage!];

    container = ProviderContainer(
      overrides: [
        authStorageProvider.overrideWithValue(fakeAuthStorage),
        webSocketServiceProvider.overrideWithValue(fakeWs),
        chatRepositoryProvider.overrideWithValue(fakeRepo),
        authProvider.overrideWith((ref) => FakeAuthNotifier(testUser)),
      ],
    );
    // Initialize conversationsProvider so it is eagerly listening to events
    container.read(conversationsProvider);
  });

  tearDown(() {
    container.dispose();
    fakeWs.dispose();
  });

  group('Real-time WebSocket event handling & State updates', () {
    test('conversation.updated replaces conversation in list and resets unread for open chat', () async {
      final convNotifier = container.read(conversationsProvider.notifier);
      await convNotifier.refresh();

      expect(container.read(conversationsProvider).conversations.first.unreadCount, 2);

      // Set active conversation to 10
      container.read(activeConversationIdProvider.notifier).state = 10;

      // Server sends conversation.updated event with unread_count: 5
      fakeWs.emitEvent({
        'event': 'conversation.updated',
        'data': {
          'conversation': {
            'id': 10,
            'peer': peerUser.toJson(),
            'unread_count': 5,
            'updated_at': '2026-11-05T09:00:00Z',
            'last_message': {
              'id': 101,
              'conversation_id': 10,
              'sender_id': 2,
              'type': 'text',
              'text': 'New message arrived',
              'status': 'sent',
              'created_at': '2026-11-05T09:00:00Z',
            },
          },
        },
      });

      // Pump microtasks for stream event
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updated = container.read(conversationsProvider).conversations.first;
      expect(updated.id, 10);
      expect(updated.lastMessage?.text, 'New message arrived');
      // Because conversation 10 is currently open, unread count is optimistic 0
      expect(updated.unreadCount, 0);
    });

    test('message.status updates ticks in real-time across messages and conversation preview', () async {
      final chatNotifier = container.read(chatMessagesProvider(10).notifier);
      await chatNotifier.fetchLatest();

      expect(container.read(chatMessagesProvider(10)).messages.first.status, MessageStatus.sent);

      // Server emits message.status read
      fakeWs.emitEvent({
        'event': 'message.status',
        'data': {
          'conversation_id': 10,
          'message_ids': [100],
          'status': 'read',
        },
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert ticks changed in open chat messages
      final msg = container.read(chatMessagesProvider(10)).messages.first;
      expect(msg.status, MessageStatus.read);

      // Assert ticks changed in conversations list preview
      final conv = container.read(conversationsProvider).conversations.first;
      expect(conv.lastMessage?.status, MessageStatus.read);
    });

    test('message.deleted creates tombstone in open chat and updates conversation preview', () async {
      final chatNotifier = container.read(chatMessagesProvider(10).notifier);
      await chatNotifier.fetchLatest();

      expect(container.read(chatMessagesProvider(10)).messages.first.deleted, false);

      // Server emits message.deleted
      fakeWs.emitEvent({
        'event': 'message.deleted',
        'data': {
          'conversation_id': 10,
          'message_id': 100,
        },
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Assert message is tombstone
      final msg = container.read(chatMessagesProvider(10)).messages.first;
      expect(msg.deleted, true);
      expect(msg.text, isNull);

      // Assert conversation last message is tombstone
      final conv = container.read(conversationsProvider).conversations.first;
      expect(conv.lastMessage?.deleted, true);
      expect(conv.lastMessage?.text, isNull);
    });

    test('message.new deduplicates and appends to open chat', () async {
      final chatNotifier = container.read(chatMessagesProvider(10).notifier);
      await chatNotifier.fetchLatest();

      expect(container.read(chatMessagesProvider(10)).messages.length, 1);

      // Emit new message frame
      fakeWs.emitEvent({
        'event': 'message.new',
        'data': {
          'message': {
            'id': 105,
            'conversation_id': 10,
            'sender_id': 2,
            'client_id': 'client-uuid-105',
            'type': 'text',
            'text': 'Live incoming text',
            'status': 'sent',
            'created_at': '2026-11-05T09:10:00Z',
          },
        },
      });

      // Emit duplicate of same message
      fakeWs.emitEvent({
        'event': 'message.new',
        'data': {
          'message': {
            'id': 105,
            'conversation_id': 10,
            'sender_id': 2,
            'client_id': 'client-uuid-105',
            'type': 'text',
            'text': 'Live incoming text',
            'status': 'sent',
            'created_at': '2026-11-05T09:10:00Z',
          },
        },
      });

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should contain 2 messages total, not 3 (deduplicated)
      final messages = container.read(chatMessagesProvider(10)).messages;
      expect(messages.length, 2);
      expect(messages.last.id, 105);
      expect(messages.last.text, 'Live incoming text');
    });

    test('reconnect resync triggers fetchLatest for open chat and refresh for conversations', () async {
      final chatNotifier = container.read(chatMessagesProvider(10).notifier);
      await chatNotifier.fetchLatest();

      expect(fakeRepo.messages.length, 1);

      // Add message on backend while offline
      fakeRepo.messages.add(
        const MessageModel(
          id: 110,
          conversationId: 10,
          senderId: 2,
          type: 'text',
          text: 'Message received while socket dropped',
          createdAt: '2026-11-05T09:30:00Z',
        ),
      );

      // Trigger socket reconnect resync
      fakeWs.emitResync();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final updatedMessages = container.read(chatMessagesProvider(10)).messages;
      expect(updatedMessages.length, 2);
      expect(updatedMessages.any((m) => m.id == 110), true);
    });
  });
}

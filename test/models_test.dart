import 'package:chaty/features/auth/domain/user_model.dart';
import 'package:chaty/features/chat/domain/conversation_model.dart';
import 'package:chaty/features/chat/domain/message_model.dart';
import 'package:chaty/features/stories/domain/story_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Serialization', () {
    test('parses and serializes UserModel correctly', () {
      final json = {
        'id': 42,
        'username': 'ahmed',
        'display_name': 'Ahmed Ali',
        'bio': 'Software Engineer',
        'avatar_file_id': 101,
        'is_following': true,
        'is_follower': false,
        'online': true,
        'last_seen': '2026-11-05T07:00:00Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 42);
      expect(user.username, 'ahmed');
      expect(user.displayName, 'Ahmed Ali');
      expect(user.bio, 'Software Engineer');
      expect(user.avatarFileId, 101);
      expect(user.isFollowing, true);
      expect(user.isFollower, false);
      expect(user.online, true);

      final encoded = user.toJson();
      expect(encoded['id'], 42);
      expect(encoded['username'], 'ahmed');
      expect(encoded['display_name'], 'Ahmed Ali');
    });
  });

  group('MessageModel Serialization', () {
    test('parses text message', () {
      final json = {
        'id': 1,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'client-uuid-1',
        'type': 'text',
        'text': 'Hello world!',
        'status': 'delivered',
        'created_at': '2026-11-05T07:10:00Z',
      };

      final message = MessageModel.fromJson(json);
      expect(message.id, 1);
      expect(message.conversationId, 10);
      expect(message.senderId, 42);
      expect(message.isText, true);
      expect(message.text, 'Hello world!');
      expect(message.status, MessageStatus.delivered);
    });

    test('parses sticker message', () {
      final json = {
        'id': 2,
        'conversation_id': 10,
        'sender_id': 42,
        'type': 'sticker',
        'sticker': {'pack': 'cats', 'id': 'cat_happy'},
        'status': 'read',
        'created_at': '2026-11-05T07:11:00Z',
      };

      final message = MessageModel.fromJson(json);
      expect(message.isSticker, true);
      expect(message.sticker?.pack, 'cats');
      expect(message.sticker?.id, 'cat_happy');
      expect(message.status, MessageStatus.read);
    });

    test('parses attachment message', () {
      final json = {
        'id': 3,
        'conversation_id': 10,
        'sender_id': 42,
        'type': 'audio',
        'attachment': {
          'file_id': 50,
          'name': 'voice_note.m4a',
          'size': 120450,
          'mime': 'audio/m4a',
          'duration_ms': 5200,
        },
        'status': 'sent',
        'created_at': '2026-11-05T07:12:00Z',
      };

      final message = MessageModel.fromJson(json);
      expect(message.isAudio, true);
      expect(message.attachment?.fileId, 50);
      expect(message.attachment?.durationMs, 5200);
      expect(message.status, MessageStatus.sent);
    });
  });

  group('ConversationModel Serialization', () {
    test('parses ConversationModel correctly', () {
      final json = {
        'id': 10,
        'user1_id': 42,
        'user2_id': 99,
        'other_user': {
          'id': 99,
          'username': 'sara',
          'display_name': 'Sara',
          'online': true,
        },
        'last_message': {
          'id': 100,
          'conversation_id': 10,
          'sender_id': 99,
          'type': 'text',
          'text': 'See you soon!',
          'status': 'read',
          'created_at': '2026-11-05T07:15:00Z',
        },
        'unread_count': 2,
        'updated_at': '2026-11-05T07:15:00Z',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 10);
      expect(conv.otherUser.id, 99);
      expect(conv.otherUser.displayName, 'Sara');
      expect(conv.unreadCount, 2);
      expect(conv.lastMessage?.text, 'See you soon!');
    });
  });

  group('StoryModel Serialization', () {
    test('parses photo and text stories correctly', () {
      final jsonText = {
        'id': 5,
        'user_id': 42,
        'type': 'text',
        'text': 'Good morning!',
        'bg_color': '#1E88E5',
        'created_at': '2026-11-05T06:00:00Z',
        'viewer_count': 12,
        'seen': true,
      };

      final story = StoryModel.fromJson(jsonText);
      expect(story.id, 5);
      expect(story.isText, true);
      expect(story.text, 'Good morning!');
      expect(story.bgColor, '#1E88E5');
      expect(story.viewerCount, 12);
      expect(story.seen, true);
    });
  });
}

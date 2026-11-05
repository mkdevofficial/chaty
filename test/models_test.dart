import 'package:chaty/features/auth/domain/user_model.dart';
import 'package:chaty/features/chat/domain/conversation_model.dart';
import 'package:chaty/features/chat/domain/message_model.dart';
import 'package:chaty/features/stories/domain/story_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Serialization & Contract Compliance', () {
    test('parses full user object with display_name', () {
      final json = {
        'id': 42,
        'username': 'mokhtar',
        'display_name': 'Mokhtar Eby',
        'bio': 'Flutter developer',
        'avatar_file_id': 101,
        'is_following': true,
        'is_follower': false,
        'online': true,
        'last_seen': '2026-11-05T07:00:00Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 42);
      expect(user.username, 'mokhtar');
      expect(user.displayName, 'Mokhtar Eby');
      expect(user.initials, 'ME');
      expect(user.bio, 'Flutter developer');
      expect(user.avatarFileId, 101);
      expect(user.isFollowing, true);
      expect(user.isFollower, false);
      expect(user.online, true);
      expect(user.lastSeen, '2026-11-05T07:00:00Z');

      final encoded = user.toJson();
      expect(encoded['id'], 42);
      expect(encoded['username'], 'mokhtar');
      expect(encoded['display_name'], 'Mokhtar Eby');
    });

    test('falls back to username when display_name is empty or null', () {
      final json = {
        'id': 7,
        'username': 'sarah_connor',
        'display_name': '',
        'bio': '',
        'avatar_file_id': null,
        'is_following': false,
        'is_follower': true,
        'online': false,
        'last_seen': null,
      };

      final user = UserModel.fromJson(json);
      expect(user.displayName, '@sarah_connor');
      expect(user.initials, 'SA');
    });
  });

  group('ConversationModel Serialization & Contract Compliance', () {
    test('parses Conversation with contract "peer" object', () {
      final json = {
        'id': 15,
        'peer': {
          'id': 99,
          'username': 'layla',
          'display_name': 'Layla Hassan',
          'avatar_file_id': 88,
          'is_following': true,
          'is_follower': true,
          'online': true,
          'last_seen': null,
        },
        'last_message': {
          'id': 101,
          'conversation_id': 15,
          'sender_id': 99,
          'type': 'text',
          'text': 'See you at 5!',
          'status': 'read',
          'created_at': '2026-11-05T08:00:00Z',
        },
        'unread_count': 3,
        'updated_at': '2026-11-05T08:00:00Z',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 15);
      expect(conv.peer.id, 99);
      expect(conv.peer.displayName, 'Layla Hassan');
      expect(conv.peer.initials, 'LH');
      expect(conv.peer.online, true);
      expect(conv.lastMessage?.text, 'See you at 5!');
      expect(conv.unreadCount, 3);
    });

    test('tolerates live server "user" field for peer', () {
      final json = {
        'id': 20,
        'user': {
          'id': 102,
          'username': 'karim',
          'display_name': 'Karim Omar',
          'online': false,
        },
        'last_message': null,
        'unread_count': 0,
        'updated_at': '2026-11-05T08:30:00Z',
      };

      final conv = ConversationModel.fromJson(json);
      expect(conv.id, 20);
      expect(conv.peer.id, 102);
      expect(conv.peer.displayName, 'Karim Omar');
      expect(conv.otherUser.displayName, 'Karim Omar');
    });
  });

  group('MessageModel Serialization for all 5 types', () {
    test('parses text message', () {
      final json = {
        'id': 1,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'cid-text-1',
        'type': 'text',
        'text': 'Hello world!',
        'status': 'delivered',
        'created_at': '2026-11-05T07:10:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isText, true);
      expect(msg.text, 'Hello world!');
      expect(msg.status, MessageStatus.delivered);
    });

    test('parses image message with attachment dimensions', () {
      final json = {
        'id': 2,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'cid-img-1',
        'type': 'image',
        'text': 'Check this photo',
        'attachment': {
          'file_id': 201,
          'name': 'sunset.jpg',
          'size': 450200,
          'mime': 'image/jpeg',
          'width': 1920,
          'height': 1080,
        },
        'status': 'sent',
        'created_at': '2026-11-05T07:11:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isImage, true);
      expect(msg.attachment?.fileId, 201);
      expect(msg.attachment?.width, 1920);
      expect(msg.attachment?.height, 1080);
      expect(msg.attachment?.mime, 'image/jpeg');
      expect(msg.status, MessageStatus.sent);
    });

    test('parses audio message with duration_ms', () {
      final json = {
        'id': 3,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'cid-aud-1',
        'type': 'audio',
        'attachment': {
          'file_id': 202,
          'name': 'voice_123.m4a',
          'size': 35000,
          'mime': 'audio/mp4',
          'duration_ms': 4200,
        },
        'status': 'read',
        'created_at': '2026-11-05T07:12:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isAudio, true);
      expect(msg.attachment?.fileId, 202);
      expect(msg.attachment?.durationMs, 4200);
      expect(msg.status, MessageStatus.read);
    });

    test('parses file document message', () {
      final json = {
        'id': 4,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'cid-file-1',
        'type': 'file',
        'attachment': {
          'file_id': 203,
          'name': 'contract.pdf',
          'size': 1048576,
          'mime': 'application/pdf',
        },
        'status': 'delivered',
        'created_at': '2026-11-05T07:13:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isFile, true);
      expect(msg.attachment?.name, 'contract.pdf');
      expect(msg.attachment?.size, 1048576);
      expect(msg.status, MessageStatus.delivered);
    });

    test('parses sticker message with pack and id', () {
      final json = {
        'id': 5,
        'conversation_id': 10,
        'sender_id': 42,
        'client_id': 'cid-stk-1',
        'type': 'sticker',
        'sticker': {'pack': 'emojis', 'id': 'fire'},
        'status': 'sent',
        'created_at': '2026-11-05T07:14:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.isSticker, true);
      expect(msg.sticker?.pack, 'emojis');
      expect(msg.sticker?.id, 'fire');
      expect(msg.status, MessageStatus.sent);
    });
  });

  group('Story and StoryGroup Serialization', () {
    test('parses image and text stories with view counts', () {
      final textJson = {
        'id': 10,
        'user_id': 42,
        'type': 'text',
        'text': 'Having a great day!',
        'bg_color': '#FF5722',
        'created_at': '2026-11-05T06:00:00Z',
        'expires_at': '2026-11-06T06:00:00Z',
        'view_count': 5,
        'seen': false,
      };

      final textStory = StoryModel.fromJson(textJson);
      expect(textStory.isText, true);
      expect(textStory.text, 'Having a great day!');
      expect(textStory.bgColor, '#FF5722');
      expect(textStory.viewCount, 5);
      expect(textStory.seen, false);

      final imgJson = {
        'id': 11,
        'user_id': 42,
        'type': 'image',
        'file_id': 301,
        'caption': 'At the beach',
        'created_at': '2026-11-05T06:30:00Z',
        'expires_at': '2026-11-06T06:30:00Z',
        'viewer_count': 12,
        'seen': true,
      };

      final imgStory = StoryModel.fromJson(imgJson);
      expect(imgStory.isImage, true);
      expect(imgStory.fileId, 301);
      expect(imgStory.caption, 'At the beach');
      expect(imgStory.viewCount, 12);
      expect(imgStory.seen, true);
    });

    test('parses StoryGroup correctly', () {
      final groupJson = {
        'user': {
          'id': 55,
          'username': 'nadia',
          'display_name': 'Nadia B',
          'avatar_file_id': 12,
          'online': true,
        },
        'has_unseen': true,
        'stories': [
          {
            'id': 100,
            'user_id': 55,
            'type': 'text',
            'text': 'Story 1',
            'bg_color': '#00897B',
            'created_at': '2026-11-05T05:00:00Z',
            'seen': false,
          }
        ],
      };

      final group = StoryGroup.fromJson(groupJson);
      expect(group.user.id, 55);
      expect(group.user.displayName, 'Nadia B');
      expect(group.hasUnseen, true);
      expect(group.stories.length, 1);
      expect(group.stories.first.text, 'Story 1');
    });

    test('parses StoryViewerModel', () {
      final viewerJson = {
        'user': {
          'id': 77,
          'username': 'tarek',
          'display_name': 'Tarek Z',
        },
        'viewed_at': '2026-11-05T07:45:00Z',
      };

      final viewer = StoryViewerModel.fromJson(viewerJson);
      expect(viewer.user.id, 77);
      expect(viewer.user.displayName, 'Tarek Z');
      expect(viewer.viewedAt, '2026-11-05T07:45:00Z');
    });
  });

  group('Contract List Wrappers', () {
    test('parses users wrapper {"users": [...]}', () {
      final wrapper = {
        'users': [
          {'id': 1, 'username': 'u1', 'display_name': 'User 1'},
          {'id': 2, 'username': 'u2', 'display_name': 'User 2'},
        ]
      };

      final list = (wrapper['users'] as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(list.length, 2);
      expect(list[0].username, 'u1');
    });

    test('parses conversations wrapper {"conversations": [...]}', () {
      final wrapper = {
        'conversations': [
          {
            'id': 10,
            'peer': {'id': 2, 'username': 'u2', 'display_name': 'User 2'},
            'unread_count': 0,
            'updated_at': '2026-11-05T08:00:00Z',
          }
        ]
      };

      final list = (wrapper['conversations'] as List)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(list.length, 1);
      expect(list[0].peer.displayName, 'User 2');
    });

    test('parses messages wrapper {"messages": [...], "has_more": false}', () {
      final wrapper = {
        'messages': [
          {
            'id': 1,
            'conversation_id': 10,
            'sender_id': 2,
            'type': 'text',
            'text': 'Hi',
            'status': 'sent',
            'created_at': '2026-11-05T08:00:00Z',
          }
        ],
        'has_more': false,
      };

      final list = (wrapper['messages'] as List)
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(list.length, 1);
      expect(wrapper['has_more'], false);
    });

    test('parses message with reply_to object correctly', () {
      final json = {
        'id': 25,
        'conversation_id': 10,
        'sender_id': 5,
        'client_id': 'c-reply-1',
        'type': 'text',
        'text': 'This is a reply message',
        'reply_to': {
          'id': 24,
          'sender_id': 6,
          'type': 'image',
          'text': 'Photo caption',
          'deleted': false,
        },
        'status': 'sent',
        'created_at': '2026-11-05T09:00:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.id, 25);
      expect(msg.replyTo, isNotNull);
      expect(msg.replyTo!.id, 24);
      expect(msg.replyTo!.senderId, 6);
      expect(msg.replyTo!.type, 'image');
      expect(msg.replyTo!.text, 'Photo caption');
      expect(msg.replyTo!.deleted, false);
    });

    test('parses tombstone message deleted for everyone', () {
      final json = {
        'id': 30,
        'conversation_id': 10,
        'sender_id': 5,
        'type': 'text',
        'text': null,
        'attachment': null,
        'sticker': null,
        'deleted': true,
        'deleted_at': '2026-11-05T09:15:00Z',
        'status': 'sent',
        'created_at': '2026-11-05T09:00:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.id, 30);
      expect(msg.deleted, true);
      expect(msg.text, isNull);
      expect(msg.attachment, isNull);
      expect(msg.sticker, isNull);
      expect(msg.deletedAt, '2026-11-05T09:15:00Z');
    });

    test('parses message with deleted reply_to tombstone', () {
      final json = {
        'id': 31,
        'conversation_id': 10,
        'sender_id': 6,
        'type': 'text',
        'text': 'Replying to what was deleted',
        'reply_to': {
          'id': 30,
          'sender_id': 5,
          'type': 'text',
          'text': null,
          'deleted': true,
        },
        'status': 'sent',
        'created_at': '2026-11-05T09:20:00Z',
      };

      final msg = MessageModel.fromJson(json);
      expect(msg.replyTo, isNotNull);
      expect(msg.replyTo!.deleted, true);
      expect(msg.replyTo!.id, 30);
    });
  });
}

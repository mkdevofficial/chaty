import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/chat/domain/conversation_model.dart';
import '../../features/chat/domain/message_model.dart';

class AppDatabase {
  static const String _dbName = 'chaty_local.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY,
            user1_id INTEGER,
            user2_id INTEGER,
            other_user TEXT,
            last_message TEXT,
            unread_count INTEGER DEFAULT 0,
            updated_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY,
            conversation_id INTEGER,
            sender_id INTEGER,
            client_id TEXT,
            type TEXT,
            text TEXT,
            attachment TEXT,
            sticker TEXT,
            status TEXT,
            created_at TEXT,
            local_file_path TEXT
          );
        ''');

        await db.execute('''
          CREATE INDEX idx_messages_conv ON messages(conversation_id, created_at);
        ''');

        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            username TEXT,
            display_name TEXT,
            bio TEXT,
            avatar_file_id INTEGER,
            online INTEGER DEFAULT 0,
            last_seen TEXT
          );
        ''');
      },
    );
  }

  // --- Conversations ---
  Future<void> saveConversations(List<ConversationModel> conversations) async {
    final db = await database;
    final batch = db.batch();
    for (final conv in conversations) {
      batch.insert(
        'conversations',
        {
          'id': conv.id,
          'user1_id': conv.user1Id,
          'user2_id': conv.user2Id,
          'other_user': jsonEncode(conv.otherUser.toJson()),
          'last_message': conv.lastMessage != null
              ? jsonEncode(conv.lastMessage!.toJson())
              : null,
          'unread_count': conv.unreadCount,
          'updated_at': conv.updatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ConversationModel>> getCachedConversations() async {
    final db = await database;
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    final List<ConversationModel> list = [];
    for (final row in rows) {
      try {
        final otherUserJson = jsonDecode(row['other_user'] as String);
        final lastMessageJson = row['last_message'] != null
            ? jsonDecode(row['last_message'] as String)
            : null;

        list.add(
          ConversationModel(
            id: row['id'] as int,
            user1Id: (row['user1_id'] as int?) ?? 0,
            user2Id: (row['user2_id'] as int?) ?? 0,
            otherUser: UserModel.fromJson(otherUserJson as Map<String, dynamic>),
            lastMessage: lastMessageJson != null
                ? MessageModel.fromJson(lastMessageJson as Map<String, dynamic>)
                : null,
            unreadCount: (row['unread_count'] as int?) ?? 0,
            updatedAt: (row['updated_at'] as String?) ?? '',
          ),
        );
      } catch (_) {}
    }
    return list;
  }

  // --- Messages ---
  Future<void> saveMessages(List<MessageModel> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'messages',
        {
          'id': msg.id,
          'conversation_id': msg.conversationId,
          'sender_id': msg.senderId,
          'client_id': msg.clientId,
          'type': msg.type,
          'text': msg.text,
          'attachment': msg.attachment != null
              ? jsonEncode(msg.attachment!.toJson())
              : null,
          'sticker': msg.sticker != null
              ? jsonEncode(msg.sticker!.toJson())
              : null,
          'status': msg.status.value,
          'created_at': msg.createdAt,
          'local_file_path': msg.localFilePath,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveSingleMessage(MessageModel msg) async {
    final db = await database;
    await db.insert(
      'messages',
      {
        'id': msg.id,
        'conversation_id': msg.conversationId,
        'sender_id': msg.senderId,
        'client_id': msg.clientId,
        'type': msg.type,
        'text': msg.text,
        'attachment': msg.attachment != null
            ? jsonEncode(msg.attachment!.toJson())
            : null,
        'sticker': msg.sticker != null
            ? jsonEncode(msg.sticker!.toJson())
            : null,
        'status': msg.status.value,
        'created_at': msg.createdAt,
        'local_file_path': msg.localFilePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MessageModel>> getCachedMessages(int conversationId, {int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC, id ASC',
      limit: limit,
    );

    final List<MessageModel> list = [];
    for (final row in rows) {
      try {
        final attachmentJson = row['attachment'] != null
            ? jsonDecode(row['attachment'] as String)
            : null;
        final stickerJson = row['sticker'] != null
            ? jsonDecode(row['sticker'] as String)
            : null;

        list.add(
          MessageModel(
            id: row['id'] as int,
            conversationId: row['conversation_id'] as int,
            senderId: row['sender_id'] as int,
            clientId: row['client_id'] as String?,
            type: row['type'] as String,
            text: row['text'] as String?,
            attachment: attachmentJson != null
                ? MessageAttachment.fromJson(attachmentJson as Map<String, dynamic>)
                : null,
            sticker: stickerJson != null
                ? MessageSticker.fromJson(stickerJson as Map<String, dynamic>)
                : null,
            status: MessageStatusExtension.fromString(row['status'] as String?),
            createdAt: row['created_at'] as String,
            localFilePath: row['local_file_path'] as String?,
          ),
        );
      } catch (_) {}
    }
    return list;
  }

  Future<void> updateMessageStatus(int messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('conversations');
    await db.delete('messages');
    await db.delete('users');
  }
}

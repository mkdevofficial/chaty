import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Service providing direct data operations and real-time messaging via Supabase.
class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  bool get isInitialized =>
      AppConfig.useSupabase &&
      AppConfig.supabaseUrl.isNotEmpty &&
      AppConfig.supabaseAnonKey.isNotEmpty;

  // Simple password hashing matching backend SHA-256 standard
  String _hashPassword(String password) {
    final bytes = utf8.encode('chaty_salt_$password');
    return sha256.convert(bytes).toString();
  }

  // ===========================================================================
  // AUTH & USER OPERATIONS
  // ===========================================================================

  Future<Map<String, dynamic>> register({
    required String phone,
    required String username,
    required String displayName,
    required String password,
  }) async {
    final cleanPhone = phone.trim();
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
    final cleanDisplayName = displayName.trim().isNotEmpty ? displayName.trim() : cleanUsername;
    final hash = _hashPassword(password);

    // Check if phone or username already exists
    final existing = await client
        .from('users')
        .select('id, phone, username')
        .or('phone.eq.$cleanPhone,username.eq.$cleanUsername')
        .maybeSingle();

    if (existing != null) {
      if (existing['phone'] == cleanPhone) {
        throw Exception('Phone number is already registered');
      }
      if (existing['username'] == cleanUsername) {
        throw Exception('Username is already taken');
      }
    }

    final insertRes = await client.from('users').insert({
      'phone': cleanPhone,
      'username': cleanUsername,
      'display_name': cleanDisplayName,
      'password_hash': hash,
      'bio': '',
      'online': true,
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    final userId = insertRes['id'] as int;
    final token = 'sb_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'user': _serializeUser(insertRes),
      'token': token,
    };
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.trim();
    final hash = _hashPassword(password);

    final userRow = await client
        .from('users')
        .select()
        .eq('phone', cleanPhone)
        .maybeSingle();

    if (userRow == null) {
      throw Exception('User not found with this phone number');
    }

    if (userRow['password_hash'] != null && userRow['password_hash'] != hash) {
      throw Exception('Invalid password');
    }

    // Update online state
    await client.from('users').update({
      'online': true,
      'last_seen': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', userRow['id']);

    final userId = userRow['id'] as int;
    final token = 'sb_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'user': _serializeUser(userRow),
      'token': token,
    };
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? displayName,
    String? photoUrl,
    String? googleId,
  }) async {
    final cleanEmail = email?.trim().toLowerCase();
    final cleanGoogleId = googleId?.trim();

    Map<String, dynamic>? userRow;

    if (cleanGoogleId != null && cleanGoogleId.isNotEmpty) {
      userRow = await client
          .from('users')
          .select()
          .eq('google_id', cleanGoogleId)
          .maybeSingle();
    }

    if (userRow == null && cleanEmail != null && cleanEmail.isNotEmpty) {
      userRow = await client
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();
    }

    if (userRow != null) {
      // User exists, update Google metadata if needed
      await client.from('users').update({
        'google_id': cleanGoogleId ?? userRow['google_id'],
        'email': cleanEmail ?? userRow['email'],
        'online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userRow['id']);
    } else {
      // Create new user for Google Sign-In
      final baseUsername = (cleanEmail != null && cleanEmail.contains('@'))
          ? cleanEmail.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
          : 'user_${DateTime.now().millisecondsSinceEpoch % 10000}';

      var username = baseUsername;
      var counter = 1;
      while (await client.from('users').select('id').eq('username', username).maybeSingle() != null) {
        username = '${baseUsername}_$counter';
        counter++;
      }

      userRow = await client.from('users').insert({
        'username': username,
        'display_name': displayName?.trim().isNotEmpty == true ? displayName!.trim() : username,
        'email': cleanEmail,
        'google_id': cleanGoogleId,
        'avatar_url': photoUrl,
        'bio': '',
        'online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).select().single();
    }

    final userId = userRow['id'] as int;
    final token = 'sb_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'user': _serializeUser(userRow),
      'token': token,
    };
  }

  Future<Map<String, dynamic>> getMe(int userId) async {
    final userRow = await client
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return _serializeUser(userRow);
  }

  Future<Map<String, dynamic>> updateProfile(
    int userId, {
    String? displayName,
    String? bio,
    String? username,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (username != null) {
      final cleanUn = username.trim().toLowerCase().replaceAll('@', '');
      final existing = await client
          .from('users')
          .select('id')
          .eq('username', cleanUn)
          .neq('id', userId)
          .maybeSingle();
      if (existing != null) {
        throw Exception('Username is already taken');
      }
      updates['username'] = cleanUn;
    }

    if (updates.isEmpty) {
      return getMe(userId);
    }

    final res = await client
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return _serializeUser(res);
  }

  Future<Map<String, dynamic>> uploadAvatar(File file, int userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final mime = lookupMimeType(file.path) ?? 'image/jpeg';

    await client.storage.from('avatars').upload(
      fileName,
      file,
      fileOptions: FileOptions(contentType: mime, upsert: true),
    );

    final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);

    final res = await client
        .from('users')
        .update({'avatar_url': publicUrl})
        .eq('id', userId)
        .select()
        .single();

    return _serializeUser(res);
  }

  // ===========================================================================
  // CONVERSATION OPERATIONS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> fetchConversations(int currentUserId) async {
    final conversations = await client
        .from('conversations')
        .select()
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('updated_at', ascending: false);

    final results = <Map<String, dynamic>>[];

    for (final conv in conversations) {
      final convId = conv['id'] as int;
      final u1 = conv['user1_id'] as int;
      final u2 = conv['user2_id'] as int;
      final peerId = (u1 == currentUserId) ? u2 : u1;

      // Peer user
      final peerRow = await client
          .from('users')
          .select()
          .eq('id', peerId)
          .maybeSingle();

      if (peerRow == null) continue;

      // Last message
      final lastMsgRows = await client
          .from('messages')
          .select()
          .eq('conversation_id', convId)
          .order('id', ascending: false)
          .limit(1);

      final lastMsg = (lastMsgRows.isNotEmpty) ? _serializeMessage(lastMsgRows.first) : null;

      // Unread count
      final readRow = await client
          .from('conversation_reads')
          .select('last_read_message_id')
          .eq('conversation_id', convId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      final lastReadId = readRow != null ? (readRow['last_read_message_id'] as int? ?? 0) : 0;

      final unreadCountRes = await client
          .from('messages')
          .select('id')
          .eq('conversation_id', convId)
          .neq('sender_id', currentUserId)
          .gt('id', lastReadId);

      results.add({
        'id': convId,
        'peer': _serializeUser(peerRow),
        'last_message': lastMsg,
        'unread_count': unreadCountRes.length,
        'updated_at': conv['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
      });
    }

    return results;
  }

  Future<Map<String, dynamic>> getOrCreateConversation(int currentUserId, int otherUserId) async {
    final u1 = (currentUserId < otherUserId) ? currentUserId : otherUserId;
    final u2 = (currentUserId < otherUserId) ? otherUserId : currentUserId;

    var conv = await client
        .from('conversations')
        .select()
        .eq('user1_id', u1)
        .eq('user2_id', u2)
        .maybeSingle();

    if (conv == null) {
      conv = await client.from('conversations').insert({
        'user1_id': u1,
        'user2_id': u2,
      }).select().single();
    }

    final convId = conv['id'] as int;

    final peerRow = await client
        .from('users')
        .select()
        .eq('id', otherUserId)
        .single();

    final lastMsgRows = await client
        .from('messages')
        .select()
        .eq('conversation_id', convId)
        .order('id', ascending: false)
        .limit(1);

    final lastMsg = (lastMsgRows.isNotEmpty) ? _serializeMessage(lastMsgRows.first) : null;

    return {
      'id': convId,
      'peer': _serializeUser(peerRow),
      'last_message': lastMsg,
      'unread_count': 0,
      'updated_at': conv['updated_at'] ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ===========================================================================
  // MESSAGE OPERATIONS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> fetchMessages(
    int conversationId, {
    int? beforeMessageId,
    int limit = 30,
  }) async {
    var query = client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId);

    if (beforeMessageId != null) {
      query = query.lt('id', beforeMessageId);
    }

    final rows = await query.order('id', ascending: false).limit(limit);

    return rows.map((e) => _serializeMessage(e)).toList();
  }

  Future<Map<String, dynamic>> sendTextMessage({
    required int conversationId,
    required int senderId,
    required String text,
    String? clientId,
    int? replyToId,
  }) async {
    final res = await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'client_id': clientId,
      'type': 'text',
      'text': text,
      'reply_to_id': replyToId,
      'status': 'sent',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    await client.from('conversations').update({
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);

    return _serializeMessage(res);
  }

  Future<Map<String, dynamic>> sendStickerMessage({
    required int conversationId,
    required int senderId,
    required String pack,
    required String stickerId,
    String? clientId,
    int? replyToId,
  }) async {
    final res = await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'client_id': clientId,
      'type': 'sticker',
      'sticker_pack': pack,
      'sticker_id': stickerId,
      'reply_to_id': replyToId,
      'status': 'sent',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    await client.from('conversations').update({
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);

    return _serializeMessage(res);
  }

  Future<Map<String, dynamic>> sendAttachmentMessage({
    required int conversationId,
    required int senderId,
    required File file,
    required String type, // 'image', 'audio', 'file'
    String? caption,
    String? clientId,
    int? durationMs,
    int? width,
    int? height,
    int? replyToId,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
    final fileSize = await file.length();

    await client.storage.from('attachments').upload(
      fileName,
      file,
      fileOptions: FileOptions(contentType: mime, upsert: true),
    );

    final publicUrl = client.storage.from('attachments').getPublicUrl(fileName);

    final res = await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'client_id': clientId,
      'type': type,
      'text': caption,
      'file_url': publicUrl,
      'file_name': file.path.split('/').last,
      'file_size': fileSize,
      'mime_type': mime,
      'duration_ms': durationMs,
      'width': width,
      'height': height,
      'reply_to_id': replyToId,
      'status': 'sent',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single();

    await client.from('conversations').update({
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId);

    return _serializeMessage(res);
  }

  Future<void> markConversationRead(int conversationId, int userId) async {
    final maxMsgRows = await client
        .from('messages')
        .select('id')
        .eq('conversation_id', conversationId)
        .order('id', ascending: false)
        .limit(1);

    final maxId = maxMsgRows.isNotEmpty ? (maxMsgRows.first['id'] as int) : 0;

    await client.from('conversation_reads').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'last_read_message_id': maxId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    await client
        .from('messages')
        .update({'status': 'read'})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .neq('status', 'read');
  }

  Future<void> deleteMessage(int messageId, int userId, {bool forEveryone = false}) async {
    if (forEveryone) {
      await client
          .from('messages')
          .update({'deleted_for_all': true, 'text': null, 'file_url': null})
          .eq('id', messageId)
          .eq('sender_id', userId);
    } else {
      // Local deletion is handled on client database
    }
  }

  // ===========================================================================
  // FRIENDS & USERS
  // ===========================================================================

  Future<List<Map<String, dynamic>>> searchUsers(String query, int currentUserId) async {
    final clean = query.trim().replaceAll('@', '');
    if (clean.isEmpty) return [];

    final rows = await client
        .from('users')
        .select()
        .neq('id', currentUserId)
        .or('username.ilike.%$clean%,display_name.ilike.%$clean%,phone.ilike.%$clean%')
        .limit(25);

    final results = <Map<String, dynamic>>[];
    for (final row in rows) {
      final targetId = row['id'] as int;
      final followCheck = await client
          .from('follows')
          .select('follower_id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetId)
          .maybeSingle();

      results.add(_serializeUser(row, isFollowing: followCheck != null));
    }
    return results;
  }

  Future<void> followUser(int currentUserId, int targetUserId) async {
    await client.from('follows').upsert({
      'follower_id': currentUserId,
      'following_id': targetUserId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> unfollowUser(int currentUserId, int targetUserId) async {
    await client
        .from('follows')
        .delete()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId);
  }

  Future<List<Map<String, dynamic>>> fetchFriends(int currentUserId) async {
    final following = await client
        .from('follows')
        .select('following_id, users!follows_following_id_fkey(*)')
        .eq('follower_id', currentUserId);

    return following
        .where((e) => e['users'] != null)
        .map((e) => _serializeUser(e['users'] as Map<String, dynamic>, isFollowing: true))
        .toList();
  }

  // ===========================================================================
  // STORIES
  // ===========================================================================

  Future<List<Map<String, dynamic>>> fetchStories(int currentUserId) async {
    final followingIdsRes = await client
        .from('follows')
        .select('following_id')
        .eq('follower_id', currentUserId);

    final allowedUserIds = [
      currentUserId,
      ...followingIdsRes.map((e) => e['following_id'] as int),
    ];

    final nowIso = DateTime.now().toUtc().toIso8601String();

    final stories = await client
        .from('stories')
        .select('*, users!stories_user_id_fkey(*)')
        .inFilter('user_id', allowedUserIds)
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false);

    final results = <Map<String, dynamic>>[];
    for (final st in stories) {
      final storyId = st['id'] as int;
      final viewCheck = await client
          .from('story_views')
          .select('viewer_id')
          .eq('story_id', storyId)
          .eq('viewer_id', currentUserId)
          .maybeSingle();

      final viewsCountRes = await client
          .from('story_views')
          .select('viewer_id')
          .eq('story_id', storyId);

      results.add({
        'id': storyId,
        'user_id': st['user_id'],
        'type': st['type'],
        'caption': st['caption'],
        'text': st['text'],
        'bg_color': st['bg_color'],
        'file_url': st['media_url'],
        'created_at': st['created_at'],
        'expires_at': st['expires_at'],
        'seen': viewCheck != null,
        'view_count': viewsCountRes.length,
        'user': (st['users'] != null) ? _serializeUser(st['users'] as Map<String, dynamic>) : null,
      });
    }

    return results;
  }

  Future<Map<String, dynamic>> createStory({
    required int userId,
    required String type, // 'image', 'text'
    File? file,
    String? caption,
    String? text,
    String? bgColor,
  }) async {
    String? mediaUrl;
    if (file != null) {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final mime = lookupMimeType(file.path) ?? 'image/jpeg';
      await client.storage.from('stories').upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: mime, upsert: true),
      );
      mediaUrl = client.storage.from('stories').getPublicUrl(fileName);
    }

    final res = await client.from('stories').insert({
      'user_id': userId,
      'type': type,
      'media_url': mediaUrl,
      'caption': caption,
      'text': text,
      'bg_color': bgColor,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
    }).select().single();

    return res;
  }

  Future<void> viewStory(int storyId, int viewerId) async {
    await client.from('story_views').upsert({
      'story_id': storyId,
      'viewer_id': viewerId,
      'viewed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ===========================================================================
  // HELPER SERIALIZERS
  // ===========================================================================

  Map<String, dynamic> _serializeUser(Map<String, dynamic> row, {bool? isFollowing, bool? isFollower}) {
    return {
      'id': row['id'],
      'username': row['username'] ?? '',
      'display_name': (row['display_name'] != null && row['display_name'].toString().trim().isNotEmpty)
          ? row['display_name']
          : (row['username'] ?? 'User'),
      'bio': row['bio'] ?? '',
      'avatar_file_id': row['avatar_file_id'],
      'avatar_url': row['avatar_url'],
      'is_following': isFollowing ?? (row['is_following'] == true),
      'is_follower': isFollower ?? (row['is_follower'] == true),
      'online': row['online'] == true,
      'last_seen': row['last_seen'],
      'email': row['email'],
      'google_id': row['google_id'],
    };
  }

  Map<String, dynamic> _serializeMessage(Map<String, dynamic> row) {
    Map<String, dynamic>? attachment;
    if (row['file_url'] != null || row['file_id'] != null) {
      attachment = {
        'file_id': row['file_id'] ?? row['id'],
        'name': row['file_name'],
        'size': row['file_size'],
        'mime': row['mime_type'],
        'url': row['file_url'],
        if (row['duration_ms'] != null) 'duration_ms': row['duration_ms'],
        if (row['width'] != null) 'width': row['width'],
        if (row['height'] != null) 'height': row['height'],
      };
    }

    Map<String, dynamic>? sticker;
    if (row['type'] == 'sticker' && row['sticker_pack'] != null) {
      sticker = {
        'pack': row['sticker_pack'],
        'id': row['sticker_id'],
      };
    }

    return {
      'id': row['id'],
      'conversation_id': row['conversation_id'],
      'sender_id': row['sender_id'],
      'client_id': row['client_id'],
      'type': row['type'],
      'text': row['text'],
      'attachment': attachment,
      'sticker': sticker,
      'status': row['status'] ?? 'sent',
      'reply_to_id': row['reply_to_id'],
      'deleted_for_all': row['deleted_for_all'] == true,
      'created_at': row['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
    };
  }
}

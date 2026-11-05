import '../../auth/domain/user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final int id;
  final int user1Id;
  final int user2Id;
  final UserModel otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;
  final String updatedAt;

  const ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      user1Id: json['user1_id'] is int
          ? json['user1_id'] as int
          : (json['user1_id'] != null ? int.parse(json['user1_id'].toString()) : 0),
      user2Id: json['user2_id'] is int
          ? json['user2_id'] as int
          : (json['user2_id'] != null ? int.parse(json['user2_id'].toString()) : 0),
      otherUser: json['other_user'] != null
          ? UserModel.fromJson(json['other_user'] as Map<String, dynamic>)
          : UserModel.fromJson(json), // fallback
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] is int
          ? json['unread_count'] as int
          : (json['unread_count'] != null
              ? int.tryParse(json['unread_count'].toString()) ?? 0
              : 0),
      updatedAt: (json['updated_at'] ?? DateTime.now().toUtc().toIso8601String()) as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'other_user': otherUser.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt,
    };
  }

  ConversationModel copyWith({
    int? id,
    int? user1Id,
    int? user2Id,
    UserModel? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
    String? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

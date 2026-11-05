import '../../auth/domain/user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final int id;
  final UserModel peer;
  final MessageModel? lastMessage;
  final int unreadCount;
  final String updatedAt;

  // Compatibility getters
  UserModel get otherUser => peer;
  int get user1Id => 0;
  int get user2Id => peer.id;

  const ConversationModel({
    required this.id,
    required this.peer,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['peer'] ?? json['user'] ?? json['other_user'];
    final UserModel peerModel;
    if (userJson is Map<String, dynamic>) {
      peerModel = UserModel.fromJson(userJson);
    } else {
      peerModel = const UserModel(
        id: 0,
        username: 'user',
        displayName: 'User',
      );
    }

    return ConversationModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      peer: peerModel,
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
      'peer': peer.toJson(),
      'user': peer.toJson(),
      'other_user': peer.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt,
    };
  }

  ConversationModel copyWith({
    int? id,
    UserModel? peer,
    UserModel? otherUser,
    MessageModel? lastMessage,
    int? unreadCount,
    String? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      peer: peer ?? otherUser ?? this.peer,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

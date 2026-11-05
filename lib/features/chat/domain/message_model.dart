class MessageAttachment {
  final int fileId;
  final String? name;
  final int? size;
  final String? mime;
  final int? durationMs;
  final int? width;
  final int? height;

  const MessageAttachment({
    required this.fileId,
    this.name,
    this.size,
    this.mime,
    this.durationMs,
    this.width,
    this.height,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      fileId: json['file_id'] is int
          ? json['file_id'] as int
          : int.parse(json['file_id'].toString()),
      name: json['name'] as String?,
      size: json['size'] != null
          ? (json['size'] is int
              ? json['size'] as int
              : int.tryParse(json['size'].toString()))
          : null,
      mime: json['mime'] as String?,
      durationMs: json['duration_ms'] != null
          ? (json['duration_ms'] is int
              ? json['duration_ms'] as int
              : int.tryParse(json['duration_ms'].toString()))
          : null,
      width: json['width'] != null
          ? (json['width'] is int
              ? json['width'] as int
              : int.tryParse(json['width'].toString()))
          : null,
      height: json['height'] != null
          ? (json['height'] is int
              ? json['height'] as int
              : int.tryParse(json['height'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'name': name,
      'size': size,
      'mime': mime,
      'duration_ms': durationMs,
      'width': width,
      'height': height,
    };
  }
}

class MessageSticker {
  final String pack;
  final String id;

  const MessageSticker({
    required this.pack,
    required this.id,
  });

  factory MessageSticker.fromJson(Map<String, dynamic> json) {
    return MessageSticker(
      pack: (json['pack'] ?? '') as String,
      id: (json['id'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pack': pack,
      'id': id,
    };
  }
}

enum MessageStatus {
  pending,
  sent,
  delivered,
  read,
  failed,
}

extension MessageStatusExtension on MessageStatus {
  String get value {
    switch (this) {
      case MessageStatus.pending:
        return 'pending';
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
      case MessageStatus.failed:
        return 'failed';
    }
  }

  static MessageStatus fromString(String? val) {
    switch (val) {
      case 'pending':
        return MessageStatus.pending;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      case 'sent':
      default:
        return MessageStatus.sent;
    }
  }
}

class MessageReplyTo {
  final int id;
  final int senderId;
  final String type; // 'text', 'image', 'audio', 'file', 'sticker'
  final String? text; // truncated to 120 chars
  final bool deleted;

  const MessageReplyTo({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.deleted = false,
  });

  factory MessageReplyTo.fromJson(Map<String, dynamic> json) {
    return MessageReplyTo(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.parse(json['sender_id'].toString()),
      type: (json['type'] ?? 'text') as String,
      text: json['text'] as String?,
      deleted: json['deleted'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'type': type,
      'text': text,
      'deleted': deleted,
    };
  }
}

class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String? clientId;
  final String type; // 'text', 'image', 'audio', 'file', 'sticker'
  final String? text;
  final MessageAttachment? attachment;
  final MessageSticker? sticker;
  final MessageStatus status;
  final String createdAt;
  final String? localFilePath; // for optimistic audio/image messages
  final MessageReplyTo? replyTo;
  final bool deleted;
  final String? deletedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.clientId,
    required this.type,
    this.text,
    this.attachment,
    this.sticker,
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.localFilePath,
    this.replyTo,
    this.deleted = false,
    this.deletedAt,
  });

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isAudio => type == 'audio';
  bool get isFile => type == 'file';
  bool get isSticker => type == 'sticker';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id'] as int
          : int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id'] as int
          : int.parse(json['sender_id'].toString()),
      clientId: json['client_id'] as String?,
      type: (json['type'] ?? 'text') as String,
      text: json['text'] as String?,
      attachment: json['attachment'] != null
          ? MessageAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
          : null,
      sticker: json['sticker'] != null
          ? MessageSticker.fromJson(json['sticker'] as Map<String, dynamic>)
          : null,
      status: MessageStatusExtension.fromString(json['status'] as String?),
      createdAt: (json['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String,
      localFilePath: json['local_file_path'] as String?,
      replyTo: json['reply_to'] != null
          ? MessageReplyTo.fromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
      deleted: json['deleted'] == true,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'client_id': clientId,
      'type': type,
      'text': text,
      'attachment': attachment?.toJson(),
      'sticker': sticker?.toJson(),
      'status': status.value,
      'created_at': createdAt,
      'local_file_path': localFilePath,
      'reply_to': replyTo?.toJson(),
      'deleted': deleted,
      'deleted_at': deletedAt,
    };
  }

  MessageModel copyWith({
    int? id,
    int? conversationId,
    int? senderId,
    String? clientId,
    String? type,
    String? text,
    MessageAttachment? attachment,
    MessageSticker? sticker,
    MessageStatus? status,
    String? createdAt,
    String? localFilePath,
    MessageReplyTo? replyTo,
    bool? deleted,
    String? deletedAt,
    bool clearContent = false,
  }) {
    final isDel = deleted ?? this.deleted;
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      clientId: clientId ?? this.clientId,
      type: type ?? this.type,
      text: (isDel || clearContent) ? null : (text ?? this.text),
      attachment: (isDel || clearContent) ? null : (attachment ?? this.attachment),
      sticker: (isDel || clearContent) ? null : (sticker ?? this.sticker),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      localFilePath: (isDel || clearContent) ? null : (localFilePath ?? this.localFilePath),
      replyTo: replyTo ?? this.replyTo,
      deleted: isDel,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

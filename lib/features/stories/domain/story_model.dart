import '../../auth/domain/user_model.dart';

class StoryModel {
  final int id;
  final int userId;
  final String type; // 'image' or 'text'
  final int? fileId;
  final String? caption;
  final String? text;
  final String? bgColor;
  final String createdAt;
  final String? expiresAt;
  final int viewerCount;
  final bool seen;
  final UserModel? user;

  const StoryModel({
    required this.id,
    required this.userId,
    required this.type,
    this.fileId,
    this.caption,
    this.text,
    this.bgColor,
    required this.createdAt,
    this.expiresAt,
    this.viewerCount = 0,
    this.seen = false,
    this.user,
  });

  bool get isImage => type == 'image';
  bool get isText => type == 'text';
  int get viewCount => viewerCount;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final rawCount = json['view_count'] ?? json['viewer_count'];
    final count = rawCount is int
        ? rawCount
        : (rawCount != null ? int.tryParse(rawCount.toString()) ?? 0 : 0);

    return StoryModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.parse(json['user_id'].toString()),
      type: (json['type'] ?? 'text') as String,
      fileId: json['file_id'] != null
          ? (json['file_id'] is int
              ? json['file_id'] as int
              : int.tryParse(json['file_id'].toString()))
          : null,
      caption: json['caption'] as String?,
      text: json['text'] as String?,
      bgColor: json['bg_color'] as String?,
      createdAt: (json['created_at'] ?? DateTime.now().toUtc().toIso8601String()) as String,
      expiresAt: json['expires_at'] as String?,
      viewerCount: count,
      seen: json['seen'] == true || json['seen'] == 1,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'file_id': fileId,
      'caption': caption,
      'text': text,
      'bg_color': bgColor,
      'created_at': createdAt,
      'expires_at': expiresAt,
      'view_count': viewerCount,
      'viewer_count': viewerCount,
      'seen': seen,
      'user': user?.toJson(),
    };
  }

  StoryModel copyWith({
    int? id,
    int? userId,
    String? type,
    int? fileId,
    String? caption,
    String? text,
    String? bgColor,
    String? createdAt,
    String? expiresAt,
    int? viewerCount,
    bool? seen,
    UserModel? user,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fileId: fileId ?? this.fileId,
      caption: caption ?? this.caption,
      text: text ?? this.text,
      bgColor: bgColor ?? this.bgColor,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewerCount: viewerCount ?? this.viewerCount,
      seen: seen ?? this.seen,
      user: user ?? this.user,
    );
  }
}

class StoryGroup {
  final UserModel user;
  final bool? hasUnseenExplicit;
  final List<StoryModel> stories;

  const StoryGroup({
    required this.user,
    required this.stories,
    this.hasUnseenExplicit,
  });

  bool get hasUnseen => hasUnseenExplicit ?? stories.any((s) => !s.seen);

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
        : UserModel.fromJson(json);

    final rawStories = json['stories'] as List<dynamic>? ?? [];
    final storiesList = rawStories
        .map((e) => StoryModel.fromJson(e as Map<String, dynamic>).copyWith(user: userObj))
        .toList();

    final hasUnseen = json['has_unseen'] == true || storiesList.any((s) => !s.seen);

    return StoryGroup(
      user: userObj,
      stories: storiesList,
      hasUnseenExplicit: hasUnseen,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'has_unseen': hasUnseen,
    'stories': stories.map((s) => s.toJson()).toList(),
  };
}

class StoryViewerModel {
  final UserModel user;
  final String viewedAt;

  UserModel get viewer => user;

  const StoryViewerModel({
    required this.user,
    required this.viewedAt,
  });

  factory StoryViewerModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? json['viewer'] ?? json;
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : const UserModel(id: 0, username: 'user', displayName: 'User');

    return StoryViewerModel(
      user: user,
      viewedAt: (json['viewed_at'] ?? DateTime.now().toUtc().toIso8601String()) as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'viewed_at': viewedAt,
  };
}

class UserModel {
  final int id;
  final String username;
  final String displayName;
  final String bio;
  final int? avatarFileId;
  final bool isFollowing;
  final bool isFollower;
  final bool online;
  final String? lastSeen;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.avatarFileId,
    this.isFollowing = false,
    this.isFollower = false,
    this.online = false,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final un = (json['username'] ?? '').toString().trim();
    final dn = (json['display_name'] ?? '').toString().trim();
    final resolvedName = dn.isNotEmpty ? dn : (un.isNotEmpty ? '@$un' : 'User');

    return UserModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      username: un,
      displayName: resolvedName,
      bio: (json['bio'] ?? '') as String,
      avatarFileId: json['avatar_file_id'] != null
          ? (json['avatar_file_id'] is int
              ? json['avatar_file_id'] as int
              : int.tryParse(json['avatar_file_id'].toString()))
          : null,
      isFollowing: json['is_following'] == true || json['is_following'] == 1,
      isFollower: json['is_follower'] == true || json['is_follower'] == 1,
      online: json['online'] == true || json['online'] == 1,
      lastSeen: json['last_seen'] as String?,
    );
  }

  String get initials {
    final clean = (displayName.isNotEmpty ? displayName : username)
        .replaceFirst('@', '')
        .trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_file_id': avatarFileId,
      'is_following': isFollowing,
      'is_follower': isFollower,
      'online': online,
      'last_seen': lastSeen,
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? displayName,
    String? bio,
    int? avatarFileId,
    bool? isFollowing,
    bool? isFollower,
    bool? online,
    String? lastSeen,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarFileId: avatarFileId ?? this.avatarFileId,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}

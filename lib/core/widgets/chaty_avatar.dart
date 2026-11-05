import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../providers/core_providers.dart';

class ChatyAvatar extends ConsumerWidget {
  final int? avatarFileId;
  final String name;
  final double radius;
  final bool isOnline;
  final bool hasStory;
  final bool hasUnseenStory;
  final bool showAddBadge;
  final VoidCallback? onTap;

  const ChatyAvatar({
    super.key,
    this.avatarFileId,
    required this.name,
    this.radius = 24,
    this.isOnline = false,
    this.hasStory = false,
    this.hasUnseenStory = false,
    this.showAddBadge = false,
    this.onTap,
  });

  String _getInitials(String input) {
    final clean = input.replaceFirst('@', '').trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length > 1) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return clean.substring(0, clean.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getAvatarBg(String input) {
    final colors = [
      const Color(0xFF00A884),
      const Color(0xFF0288D1),
      const Color(0xFF7C4DFF),
      const Color(0xFFFF6F00),
      const Color(0xFFE91E63),
      const Color(0xFF009688),
      const Color(0xFF3F51B5),
    ];
    final hash = input.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStorage = ref.watch(authStorageProvider);
    final theme = Theme.of(context);

    Widget avatarContent;

    if (avatarFileId != null && avatarFileId! > 0) {
      avatarContent = FutureBuilder<String?>(
        future: authStorage.getToken(),
        builder: (context, snapshot) {
          final token = snapshot.data;
          if (token == null || token.isEmpty) {
            return _buildInitialsAvatar();
          }
          final headers = {'Authorization': 'Bearer $token'};

          return CachedNetworkImage(
            imageUrl: AppConfig.getFileUrl(avatarFileId!),
            httpHeaders: headers,
            imageBuilder: (context, imageProvider) => CircleAvatar(
              radius: radius,
              backgroundImage: imageProvider,
            ),
            placeholder: (context, url) => CircleAvatar(
              radius: radius,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: SizedBox(
                width: radius,
                height: radius,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _buildInitialsAvatar(),
          );
        },
      );
    } else {
      avatarContent = _buildInitialsAvatar();
    }

    Widget content = avatarContent;

    // Story ring wrapper
    if (hasStory) {
      final ringColor = hasUnseenStory
          ? [
              const Color(0xFF00A884),
              const Color(0xFF0288D1),
              const Color(0xFF7C4DFF),
            ]
          : [Colors.grey.shade400, Colors.grey.shade500];

      content = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: ringColor,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
          ),
          child: content,
        ),
      );
    }

    // Overlay indicators: Online green dot or Add (+) badge
    if (isOnline || showAddBadge) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (isOnline && !showAddBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.42,
                height: radius * 0.42,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D856),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.5,
                  ),
                ),
              ),
            ),
          if (showAddBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.55,
                height: radius * 0.55,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: radius * 0.38,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _getAvatarBg(name),
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

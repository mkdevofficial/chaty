import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../auth/domain/user_model.dart';
import '../../chat/presentation/providers/conversations_provider.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../stories/presentation/stories_provider.dart';
import '../../stories/presentation/story_viewer_screen.dart';
import '../../friends/presentation/friends_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const UserProfileScreen({super.key, required this.user});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final repo = ref.read(friendsRepositoryProvider);
      final fresh = await repo.getUser(_user.id);
      if (mounted) {
        setState(() {
          _user = fresh;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    final success = await ref.read(friendsProvider.notifier).toggleFollow(_user);
    if (success && mounted) {
      setState(() {
        _user = _user.copyWith(isFollowing: !_user.isFollowing);
      });
    }
  }

  Future<void> _startChat() async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(_user.id);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final storiesState = ref.watch(storiesProvider);

    final userStoryGroup = storiesState.storyGroups
        .where((g) => g.user.id == _user.id)
        .firstOrNull;

    final hasStory = userStoryGroup != null && userStoryGroup.stories.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_user.displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // User Avatar with Story Ring if active stories exist
            Center(
              child: ChatyAvatar(
                name: _user.displayName,
                avatarFileId: _user.avatarFileId,
                radius: 56,
                isOnline: _user.online,
                hasStory: hasStory,
                hasUnseenStory: userStoryGroup?.hasUnseen ?? false,
                onTap: hasStory
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StoryViewerScreen(
                              storyGroup: userStoryGroup,
                              isOwnStory: false,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Display Name
            Text(
              _user.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // @Username
            Text(
              '@${_user.username}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Online / Last seen status
            Text(
              _user.online
                  ? strings.online
                  : DateFormatter.formatLastSeen(_user.lastSeen, isArabic: isArabic),
              style: TextStyle(
                color: _user.online
                    ? const Color(0xFF00D856)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Follow / Message)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: Text(strings.sendMessage),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: _user.isFollowing
                          ? theme.colorScheme.surfaceContainerHighest
                          : null,
                    ),
                    onPressed: _toggleFollow,
                    icon: Icon(
                      _user.isFollowing ? Icons.check : Icons.person_add,
                      color: _user.isFollowing
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.primary,
                    ),
                    label: Text(
                      _user.isFollowing ? strings.following : strings.follow,
                      style: TextStyle(
                        color: _user.isFollowing
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Bio card
            if (_user.bio.isNotEmpty) ...[
              Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  strings.bio,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _user.bio,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../auth/domain/user_model.dart';
import '../../chat/presentation/providers/conversations_provider.dart';
import '../../chat/presentation/screens/chat_screen.dart';
import '../../profile/presentation/user_profile_screen.dart';
import 'friends_provider.dart';

class FriendsListScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const FriendsListScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startChatWithUser(UserModel user) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.getOrCreateConversation(user.id);
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
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);
    final friendsState = ref.watch(friendsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.followers),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(text: '${strings.following} (${friendsState.following.length})'),
            Tab(text: '${strings.followers} (${friendsState.followers.length})'),
          ],
        ),
      ),
      body: friendsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. Following Tab
                RefreshIndicator(
                  onRefresh: () => ref.read(friendsProvider.notifier).fetchFriends(),
                  child: friendsState.following.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: strings.following,
                          subtitle: strings.noUsersFound,
                        )
                      : ListView.builder(
                          itemCount: friendsState.following.length,
                          itemBuilder: (context, index) {
                            final user = friendsState.following[index];
                            return _buildUserTile(user, theme, strings);
                          },
                        ),
                ),

                // 2. Followers Tab
                RefreshIndicator(
                  onRefresh: () => ref.read(friendsProvider.notifier).fetchFriends(),
                  child: friendsState.followers.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: strings.followers,
                          subtitle: strings.noUsersFound,
                        )
                      : ListView.builder(
                          itemCount: friendsState.followers.length,
                          itemBuilder: (context, index) {
                            final user = friendsState.followers[index];
                            return _buildUserTile(user, theme, strings);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserTile(UserModel user, ThemeData theme, dynamic strings) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(user: user),
          ),
        );
      },
      leading: ChatyAvatar(
        name: user.displayName,
        avatarFileId: user.avatarFileId,
        isOnline: user.online,
        radius: 24,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('@${user.username}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _startChatWithUser(user),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 36),
              backgroundColor: user.isFollowing
                  ? theme.colorScheme.surfaceContainerHighest
                  : null,
            ),
            onPressed: () {
              ref.read(friendsProvider.notifier).toggleFollow(user);
            },
            child: Text(
              user.isFollowing ? strings.unfollow : strings.follow,
              style: TextStyle(
                fontSize: 13,
                color: user.isFollowing
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    ref.read(friendsProvider.notifier).search(val);
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
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: strings.searchPlaceholder,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
            ),
        ],
      ),
      body: friendsState.isSearching
          ? const Center(child: CircularProgressIndicator())
          : friendsState.searchResults.isEmpty
              ? EmptyState(
                  icon: Icons.search_rounded,
                  title: strings.searchUsers,
                  subtitle: strings.searchPlaceholder,
                )
              : ListView.builder(
                  itemCount: friendsState.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = friendsState.searchResults[index];
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
                            key: Key('follow_button_${user.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              minimumSize: const Size(60, 36),
                              backgroundColor: user.isFollowing
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : null,
                            ),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(friendsProvider.notifier)
                                    .toggleFollow(user);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update follow status: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
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
                  },
                ),
    );
  }
}

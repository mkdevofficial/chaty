import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../friends/presentation/search_users_screen.dart';
import '../../../profile/presentation/my_profile_screen.dart';
import '../../../settings/presentation/settings_screen.dart';
import '../../../stories/presentation/stories_bar.dart';
import '../../domain/message_model.dart';
import '../providers/conversations_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  Widget _buildLastMessagePreview(
    BuildContext context,
    MessageModel? lastMessage,
    dynamic strings,
  ) {
    if (lastMessage == null) {
      return Text(
        strings.startConversation,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    Widget iconWidget = const SizedBox.shrink();
    String textPreview = lastMessage.text ?? '';

    if (lastMessage.isImage) {
      iconWidget = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.photo_camera, size: 15, color: Colors.grey),
      );
      if (textPreview.isEmpty) textPreview = strings.photo;
    } else if (lastMessage.isAudio) {
      iconWidget = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.mic, size: 15, color: Colors.grey),
      );
      textPreview = strings.voiceNote;
    } else if (lastMessage.isFile) {
      iconWidget = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.insert_drive_file, size: 15, color: Colors.grey),
      );
      textPreview = lastMessage.attachment?.name ?? strings.file;
    } else if (lastMessage.isSticker) {
      iconWidget = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 3),
        child: Icon(Icons.emoji_emotions, size: 15, color: Colors.grey),
      );
      textPreview = strings.sticker;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        Flexible(
          child: Text(
            textPreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final user = ref.watch(authProvider).user;
    final convState = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.appName,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ChatyAvatar(
            name: user?.displayName ?? 'Me',
            avatarFileId: user?.avatarFileId,
            radius: 18,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyProfileScreen(),
                ),
              );
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchUsersScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Top Stories Bar
            const SliverToBoxAdapter(
              child: StoriesBar(),
            ),

            const SliverToBoxAdapter(
              child: Divider(height: 1),
            ),

            // Loading Skeletons
            if (convState.isLoading && convState.conversations.isEmpty)
              const SliverFillRemaining(
                child: ConversationListSkeleton(),
              )
            // Empty State
            else if (convState.conversations.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: strings.noChatsYet,
                  subtitle: strings.startConversation,
                  actionText: strings.searchUsers,
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchUsersScreen(),
                      ),
                    );
                  },
                ),
              )
            // Conversations List
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final conv = convState.conversations[index];
                    final otherUser = conv.otherUser;
                    final timeStr = DateFormatter.formatConversationTime(
                      conv.lastMessage?.createdAt ?? conv.updatedAt,
                      isArabic: isArabic,
                    );

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(conversation: conv),
                          ),
                        );
                      },
                      leading: ChatyAvatar(
                        name: otherUser.displayName,
                        avatarFileId: otherUser.avatarFileId,
                        isOnline: otherUser.online,
                        radius: 26,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: conv.unreadCount > 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: conv.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: _buildLastMessagePreview(
                              context,
                              conv.lastMessage,
                              strings,
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Badge(
                              label: Text('${conv.unreadCount}'),
                              backgroundColor: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: convState.conversations.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom > 0 ? 8 : 0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SearchUsersScreen(),
              ),
            );
          },
          child: const Icon(Icons.chat_bubble_outline),
        ),
      ),
    );
  }
}

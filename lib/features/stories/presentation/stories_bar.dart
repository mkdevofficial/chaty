import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../../auth/presentation/auth_provider.dart';
import 'create_story_screen.dart';
import 'stories_provider.dart';
import 'story_viewer_screen.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;
    final currentUser = ref.watch(authProvider).user;
    final storiesState = ref.watch(storiesProvider);

    // Find own story group if any
    final ownStoryGroup = currentUser != null
        ? storiesState.storyGroups.where((g) => g.user.id == currentUser.id).firstOrNull
        : null;

    final otherGroups = currentUser != null
        ? storiesState.storyGroups.where((g) => g.user.id != currentUser.id).toList()
        : storiesState.storyGroups;

    return Container(
      height: 104,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          // My Story Item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatyAvatar(
                  radius: 28,
                  avatarFileId: currentUser?.avatarFileId,
                  name: currentUser?.displayName ?? strings.myStory,
                  hasStory: ownStoryGroup != null && ownStoryGroup.stories.isNotEmpty,
                  hasUnseenStory: ownStoryGroup?.hasUnseen ?? false,
                  showAddBadge: ownStoryGroup == null || ownStoryGroup.stories.isEmpty,
                  onTap: () {
                    if (ownStoryGroup != null && ownStoryGroup.stories.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen(
                            storyGroup: ownStoryGroup,
                            isOwnStory: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreateStoryScreen(),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 68,
                  child: Text(
                    strings.myStory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Followed Users' Stories
          ...otherGroups.map(
            (group) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChatyAvatar(
                    radius: 28,
                    avatarFileId: group.user.avatarFileId,
                    name: group.user.displayName,
                    hasStory: true,
                    hasUnseenStory: group.hasUnseen,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => StoryViewerScreen(
                            storyGroup: group,
                            isOwnStory: false,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 68,
                    child: Text(
                      group.user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

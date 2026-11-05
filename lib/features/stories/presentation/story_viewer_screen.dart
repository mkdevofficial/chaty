import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/widgets/chaty_avatar.dart';
import '../domain/story_model.dart';
import 'stories_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final StoryGroup storyGroup;
  final bool isOwnStory;

  const StoryViewerScreen({
    super.key,
    required this.storyGroup,
    required this.isOwnStory,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _animController;

  StoryModel get _currentStory => widget.storyGroup.stories[_currentIndex];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startCurrentStory();
  }

  void _startCurrentStory() {
    _animController.reset();
    _animController.forward();

    if (!widget.isOwnStory && !_currentStory.seen) {
      ref.read(storiesProvider.notifier).markStorySeen(_currentStory.id);
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.storyGroup.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startCurrentStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startCurrentStory();
    } else {
      _animController.reset();
      _animController.forward();
    }
  }

  void _pause() {
    _animController.stop();
  }

  void _resume() {
    _animController.forward();
  }

  Future<void> _showViewers() async {
    _pause();
    final repo = ref.read(storiesRepositoryProvider);
    final strings = AppLocalizations.of(context).strings;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  strings.viewers,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<StoryViewerModel>>(
                  future: repo.getStoryViewers(_currentStory.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final viewers = snapshot.data ?? [];
                    if (viewers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(strings.noViewersYet),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        final item = viewers[index];
                        return ListTile(
                          leading: ChatyAvatar(
                            name: item.viewer.displayName,
                            avatarFileId: item.viewer.avatarFileId,
                            radius: 20,
                          ),
                          title: Text(item.viewer.displayName),
                          subtitle: Text('@${item.viewer.username}'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    _resume();
  }

  Future<void> _deleteStory() async {
    _pause();
    final strings = AppLocalizations.of(context).strings;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.delete),
        content: Text(strings.deleteStoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(storiesProvider.notifier)
          .deleteStory(_currentStory.id);
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          _resume();
        }
      }
    } else {
      _resume();
    }
  }

  Color _parseBgColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF1E88E5);
    final hex = hexString.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF1E88E5);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _currentStory;
    final total = widget.storyGroup.stories.length;
    final authStorage = ref.watch(authStorageProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pause(),
        onLongPressEnd: (_) => _resume(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 200) {
            Navigator.of(context).pop();
          }
        },
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story Content (Image or Text)
            if (story.isImage && story.fileId != null)
              FutureBuilder<String?>(
                future: authStorage.getToken(),
                builder: (context, snapshot) {
                  final token = snapshot.data;
                  if (token == null || token.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }
                  final headers = {'Authorization': 'Bearer $token'};

                  return CachedNetworkImage(
                    imageUrl: AppConfig.getFileUrl(story.fileId!),
                    httpHeaders: headers,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                    ),
                  );
                },
              )
            else
              Container(
                color: _parseBgColor(story.bgColor),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  story.text ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Optional Caption for image story
            if (story.isImage && story.caption != null && story.caption!.isNotEmpty)
              Positioned(
                bottom: (widget.isOwnStory ? 70 : 30) + bottomInset,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    story.caption!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

            // Top Overlay: Progress Bars + User Info + Close
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Progress Bars
                    Row(
                      children: List.generate(total, (i) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                double value = 0.0;
                                if (i < _currentIndex) {
                                  value = 1.0;
                                } else if (i == _currentIndex) {
                                  value = _animController.value;
                                }
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // User Info Header
                    Row(
                      children: [
                        ChatyAvatar(
                          radius: 18,
                          name: widget.storyGroup.user.displayName,
                          avatarFileId: widget.storyGroup.user.avatarFileId,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.storyGroup.user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions for Owner: Viewers count & Delete
            if (widget.isOwnStory)
              Positioned(
                bottom: 24 + bottomInset,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _showViewers,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${story.viewerCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: _deleteStory,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

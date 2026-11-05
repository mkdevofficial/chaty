import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../data/stories_repository.dart';
import '../domain/story_model.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StoriesRepository(apiClient: apiClient);
});

class StoriesState {
  final List<StoryGroup> storyGroups;
  final bool isLoading;
  final String? error;

  const StoriesState({
    this.storyGroups = const [],
    this.isLoading = false,
    this.error,
  });

  StoriesState copyWith({
    List<StoryGroup>? storyGroups,
    bool? isLoading,
    String? error,
  }) {
    return StoriesState(
      storyGroups: storyGroups ?? this.storyGroups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StoriesNotifier extends StateNotifier<StoriesState> {
  final StoriesRepository _repository;
  final Ref _ref;
  StreamSubscription? _wsSubscription;

  StoriesNotifier(this._repository, this._ref) : super(const StoriesState()) {
    fetchStories();
    _initWs();
  }

  void _initWs() {
    final ws = _ref.read(webSocketServiceProvider);
    _wsSubscription = ws.events.listen((event) {
      if (event['type'] == 'story.new') {
        fetchStories();
      }
    });
  }

  Future<void> fetchStories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final groups = await _repository.fetchStories();
      state = state.copyWith(storyGroups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createImageStory({
    required File imageFile,
    String? caption,
  }) async {
    try {
      await _repository.createImageStory(imageFile: imageFile, caption: caption);
      await fetchStories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> createTextStory({
    required String text,
    required String bgColor,
  }) async {
    try {
      await _repository.createTextStory(text: text, bgColor: bgColor);
      await fetchStories();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> markStorySeen(int storyId) async {
    await _repository.markStoryViewed(storyId);
    // Locally mark story as seen
    state = state.copyWith(
      storyGroups: state.storyGroups.map((group) {
        return StoryGroup(
          user: group.user,
          stories: group.stories.map((s) {
            if (s.id == storyId) {
              return s.copyWith(seen: true);
            }
            return s;
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<bool> deleteStory(int storyId) async {
    try {
      await _repository.deleteStory(storyId);
      await fetchStories();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}

final storiesProvider =
    StateNotifierProvider<StoriesNotifier, StoriesState>((ref) {
  final repository = ref.watch(storiesRepositoryProvider);
  return StoriesNotifier(repository, ref);
});

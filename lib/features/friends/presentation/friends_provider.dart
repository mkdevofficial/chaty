import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../auth/domain/user_model.dart';
import '../../stories/presentation/stories_provider.dart';
import '../data/friends_repository.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FriendsRepository(apiClient: apiClient);
});

class FriendsState {
  final List<UserModel> following;
  final List<UserModel> followers;
  final List<UserModel> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;

  const FriendsState({
    this.following = const [],
    this.followers = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
  });

  FriendsState copyWith({
    List<UserModel>? following,
    List<UserModel>? followers,
    List<UserModel>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
  }) {
    return FriendsState(
      following: following ?? this.following,
      followers: followers ?? this.followers,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendsRepository _repository;
  final Ref _ref;

  FriendsNotifier(this._repository, this._ref) : super(const FriendsState()) {
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final following = await _repository.getFollowing();
      final followers = await _repository.getFollowers();
      state = state.copyWith(
        following: following,
        followers: followers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await _repository.searchUsers(clean);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  Future<UserModel?> toggleFollow(UserModel user) async {
    final currentlyFollowing = user.isFollowing;
    try {
      final UserModel updatedUser;
      if (currentlyFollowing) {
        updatedUser = await _repository.unfollowUser(user.id);
      } else {
        updatedUser = await _repository.followUser(user.id);
      }

      // Update in searchResults
      state = state.copyWith(
        searchResults: state.searchResults.map((u) {
          if (u.id == user.id) return updatedUser;
          return u;
        }).toList(),
      );

      // Refresh friends lists
      await fetchFriends();

      // Refresh stories after following
      _ref.read(storiesProvider.notifier).fetchStories();

      return updatedUser;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final repository = ref.watch(friendsRepositoryProvider);
  return FriendsNotifier(repository, ref);
});

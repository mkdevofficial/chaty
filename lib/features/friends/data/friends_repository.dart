import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/auth_storage.dart';
import '../../auth/domain/user_model.dart';

class FriendsRepository {
  final ApiClient apiClient;
  final SupabaseService? supabaseService;
  final AuthStorage? authStorage;

  FriendsRepository({
    required this.apiClient,
    this.supabaseService,
    this.authStorage,
  });

  bool get _shouldUseSupabase =>
      AppConfig.useSupabase && supabaseService != null && supabaseService!.isInitialized;

  Future<List<UserModel>> searchUsers(String query) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final list = await supabaseService!.searchUsers(query, currentUserId);
      return list.map((e) => UserModel.fromJson(e)).toList();
    }

    final response = await apiClient.get(
      '/users/search',
      queryParameters: {'q': query},
    );

    final List<dynamic> list = response is List
        ? response
        : (response['users'] as List<dynamic>? ?? []);

    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> getUser(int id) async {
    if (_shouldUseSupabase) {
      final data = await supabaseService!.getMe(id);
      return UserModel.fromJson(data);
    }

    final response = await apiClient.get('/users/$id');
    final data = (response is Map<String, dynamic> && response['user'] != null)
        ? response['user'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> followUser(int userId) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      await supabaseService!.followUser(currentUserId, userId);
      final user = await getUser(userId);
      return user.copyWith(isFollowing: true);
    }

    final response = await apiClient.post('/friends/$userId', data: {});
    final data = response is Map<String, dynamic>
        ? (response['user'] ?? response)
        : response;
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<UserModel> unfollowUser(int userId) async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      await supabaseService!.unfollowUser(currentUserId, userId);
      final user = await getUser(userId);
      return user.copyWith(isFollowing: false);
    }

    final response = await apiClient.delete('/friends/$userId', data: {});
    final data = response is Map<String, dynamic>
        ? (response['user'] ?? response)
        : response;
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<UserModel>> getFollowing() async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final list = await supabaseService!.fetchFriends(currentUserId);
      return list.map((e) => UserModel.fromJson(e)).toList();
    }

    final response = await apiClient.get('/friends/following');
    final List<dynamic> list = response is List
        ? response
        : (response['users'] as List<dynamic>? ??
            response['following'] as List<dynamic>? ??
            []);

    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getFollowers() async {
    if (_shouldUseSupabase) {
      final currentUserId = await authStorage?.getUserId() ?? 0;
      final list = await supabaseService!.fetchFriends(currentUserId);
      return list.map((e) => UserModel.fromJson(e)).toList();
    }

    final response = await apiClient.get('/friends/followers');
    final List<dynamic> list = response is List
        ? response
        : (response['users'] as List<dynamic>? ??
            response['followers'] as List<dynamic>? ??
            []);

    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

import '../../../core/network/api_client.dart';
import '../../auth/domain/user_model.dart';

class FriendsRepository {
  final ApiClient apiClient;

  FriendsRepository({required this.apiClient});

  Future<List<UserModel>> searchUsers(String query) async {
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
    final response = await apiClient.get('/users/$id');
    final data = (response is Map<String, dynamic> && response['user'] != null)
        ? response['user'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<void> followUser(int userId) async {
    await apiClient.post('/friends/$userId');
  }

  Future<void> unfollowUser(int userId) async {
    await apiClient.delete('/friends/$userId');
  }

  Future<List<UserModel>> getFollowing() async {
    final response = await apiClient.get('/friends/following');
    final List<dynamic> list = response is List
        ? response
        : (response['following'] as List<dynamic>? ?? []);

    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getFollowers() async {
    final response = await apiClient.get('/friends/followers');
    final List<dynamic> list = response is List
        ? response
        : (response['followers'] as List<dynamic>? ?? []);

    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}

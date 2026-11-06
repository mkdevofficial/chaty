import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final AuthStorage authStorage;

  AuthRepository({
    required this.apiClient,
    required this.authStorage,
  });

  Future<UserModel> register({
    required String phone,
    required String username,
    required String displayName,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/register',
      data: {
        'phone': phone,
        'username': username,
        'display_name': displayName,
        'password': password,
      },
    );

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    await authStorage.saveToken(token);
    await authStorage.saveUserId(user.id);

    return user;
  }

  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/auth/login',
      data: {
        'phone': phone,
        'password': password,
      },
    );

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    await authStorage.saveToken(token);
    await authStorage.saveUserId(user.id);

    return user;
  }

  Future<UserModel> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? displayName,
    String? photoUrl,
    String? googleId,
  }) async {
    final response = await apiClient.post(
      '/auth/google',
      data: {
        'id_token': ?idToken,
        'access_token': ?accessToken,
        'email': ?email,
        'display_name': ?displayName,
        'photo_url': ?photoUrl,
        'google_id': ?googleId,
      },
    );

    final token = response['token'] as String;
    final userData = response['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    await authStorage.saveToken(token);
    await authStorage.saveUserId(user.id);

    return user;
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (_) {}
    await authStorage.clear();
  }

  Future<UserModel> getMe() async {
    final response = await apiClient.get('/me');
    final userData = (response is Map<String, dynamic> && response['user'] != null)
        ? response['user'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? username,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['display_name'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (username != null) data['username'] = username;

    final response = await apiClient.patch('/me', data: data);
    final userData = (response is Map<String, dynamic> && response['user'] != null)
        ? response['user'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }

  Future<UserModel> uploadAvatar(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    String mime = 'image/jpeg';
    if (ext == 'png') mime = 'image/png';
    if (ext == 'webp') mime = 'image/webp';

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType.parse(mime),
      ),
    });

    final response = await apiClient.postMultipart('/me/avatar', formData: formData);
    final userData = (response is Map<String, dynamic> && response['user'] != null)
        ? response['user'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    return UserModel.fromJson(userData);
  }
}

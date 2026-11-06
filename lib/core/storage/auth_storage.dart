import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const String _keyToken = 'chaty_auth_token';
  static const String _keyUserId = 'chaty_user_id';
  static const String _keyUserProfile = 'chaty_user_profile';

  final FlutterSecureStorage _storage;

  AuthStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserId(int id) async {
    await _storage.write(key: _keyUserId, value: id.toString());
  }

  Future<int?> getUserId() async {
    final val = await _storage.read(key: _keyUserId);
    if (val != null) {
      return int.tryParse(val);
    }
    return null;
  }

  Future<void> saveUserProfile(String jsonStr) async {
    await _storage.write(key: _keyUserProfile, value: jsonStr);
  }

  Future<String?> getUserProfile() async {
    return await _storage.read(key: _keyUserProfile);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserProfile);
  }
}

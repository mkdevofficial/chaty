import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _prefKeyBaseUrl = 'chaty_base_url';
  static const String _prefKeyWsUrl = 'chaty_ws_url';

  static const String defaultBaseUrl = 'http://185.196.20.220:5050';
  static const String defaultWsUrl = 'ws://185.196.20.220:5050/ws';

  static String _baseUrl = defaultBaseUrl;
  static String _wsUrl = defaultWsUrl;

  static String get baseUrl => _baseUrl;
  static String get wsUrl => _wsUrl;

  static String get apiUrl => '$_baseUrl/api';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKeyBaseUrl) ?? defaultBaseUrl;
    _wsUrl = prefs.getString(_prefKeyWsUrl) ?? defaultWsUrl;
  }

  static Future<void> updateServerConfig({
    required String newBaseUrl,
    required String newWsUrl,
  }) async {
    _baseUrl = newBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _wsUrl = newWsUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, _baseUrl);
    await prefs.setString(_prefKeyWsUrl, _wsUrl);
  }

  static Future<void> resetToDefault() async {
    _baseUrl = defaultBaseUrl;
    _wsUrl = defaultWsUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyBaseUrl);
    await prefs.remove(_prefKeyWsUrl);
  }

  static String getFileUrl(int fileId) {
    return '$apiUrl/files/$fileId';
  }
}

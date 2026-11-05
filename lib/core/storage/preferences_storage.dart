import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStorage {
  static const String _keyThemeMode = 'chaty_theme_mode';
  static const String _keyAccentColor = 'chaty_accent_color';
  static const String _keyWallpaper = 'chaty_chat_wallpaper';
  static const String _keyLocale = 'chaty_locale';
  static const String _keyRecentStickers = 'chaty_recent_stickers';

  final SharedPreferences _prefs;

  PreferencesStorage(this._prefs);

  static Future<PreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesStorage(prefs);
  }

  ThemeMode getThemeMode() {
    final val = _prefs.getString(_keyThemeMode);
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _prefs.setString(_keyThemeMode, val);
  }

  int getAccentColorIndex() {
    return _prefs.getInt(_keyAccentColor) ?? 0;
  }

  Future<void> setAccentColorIndex(int index) async {
    await _prefs.setInt(_keyAccentColor, index);
  }

  String getWallpaper() {
    return _prefs.getString(_keyWallpaper) ?? 'default';
  }

  Future<void> setWallpaper(String wallpaper) async {
    await _prefs.setString(_keyWallpaper, wallpaper);
  }

  Locale getLocale() {
    final val = _prefs.getString(_keyLocale);
    if (val == 'en') return const Locale('en');
    return const Locale('ar'); // Default is Arabic (RTL)
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

  List<Map<String, String>> getRecentStickers() {
    final raw = _prefs.getString(_keyRecentStickers);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecentSticker(String pack, String id) async {
    final list = getRecentStickers();
    list.removeWhere((item) => item['pack'] == pack && item['id'] == id);
    list.insert(0, {'pack': pack, 'id': id});
    if (list.length > 24) {
      list.removeRange(24, list.length);
    }
    await _prefs.setString(_keyRecentStickers, jsonEncode(list));
  }
}

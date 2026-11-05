import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/preferences_storage.dart';
import 'app_colors.dart';

final preferencesStorageProvider = Provider<PreferencesStorage>((ref) {
  throw UnimplementedError('preferencesStorageProvider must be initialized');
});

class ThemeState {
  final ThemeMode themeMode;
  final AppAccentColor accentColor;
  final String wallpaper;
  final Locale locale;

  const ThemeState({
    required this.themeMode,
    required this.accentColor,
    required this.wallpaper,
    required this.locale,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppAccentColor? accentColor,
    String? wallpaper,
    Locale? locale,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      wallpaper: wallpaper ?? this.wallpaper,
      locale: locale ?? this.locale,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  final PreferencesStorage _prefs;

  ThemeNotifier(this._prefs)
      : super(
          ThemeState(
            themeMode: _prefs.getThemeMode(),
            accentColor: AppAccentColor.values[
                _prefs.getAccentColorIndex().clamp(0, AppAccentColor.values.length - 1)],
            wallpaper: _prefs.getWallpaper(),
            locale: _prefs.getLocale(),
          ),
        );

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setThemeMode(mode);
  }

  Future<void> setAccentColor(AppAccentColor color) async {
    state = state.copyWith(accentColor: color);
    await _prefs.setAccentColorIndex(color.index);
  }

  Future<void> setWallpaper(String wallpaper) async {
    state = state.copyWith(wallpaper: wallpaper);
    await _prefs.setWallpaper(wallpaper);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setLocale(locale);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(preferencesStorageProvider);
  return ThemeNotifier(prefs);
});

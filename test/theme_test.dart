import 'package:chaty/core/theme/app_colors.dart';
import 'package:chaty/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme Tests', () {
    test('AppAccentColor has 4 distinct accent colors', () {
      expect(AppAccentColor.values.length, greaterThanOrEqualTo(4));
      final colors = AppAccentColor.values.map((a) => a.seedColor).toSet();
      expect(colors.length, 4);
    });

    test('creates light and dark themes properly', () {
      for (final accent in AppAccentColor.values) {
        final light = AppTheme.lightTheme(accent);
        final dark = AppTheme.darkTheme(accent);

        expect(light.useMaterial3, true);
        expect(dark.useMaterial3, true);
        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
      }
    });
  });
}

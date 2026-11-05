import 'package:flutter/material.dart';

enum AppAccentColor {
  emerald,
  ocean,
  violet,
  amber,
}

extension AppAccentColorExtension on AppAccentColor {
  String get name {
    switch (this) {
      case AppAccentColor.emerald:
        return 'Emerald';
      case AppAccentColor.ocean:
        return 'Ocean';
      case AppAccentColor.violet:
        return 'Royal Violet';
      case AppAccentColor.amber:
        return 'Sunset Amber';
    }
  }

  Color get seedColor {
    switch (this) {
      case AppAccentColor.emerald:
        return const Color(0xFF00A884);
      case AppAccentColor.ocean:
        return const Color(0xFF0288D1);
      case AppAccentColor.violet:
        return const Color(0xFF7C4DFF);
      case AppAccentColor.amber:
        return const Color(0xFFFF6F00);
    }
  }
}

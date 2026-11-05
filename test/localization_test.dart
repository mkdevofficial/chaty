import 'package:chaty/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('Arabic dictionary contains all essential strings', () {
      final loc = AppLocalizations(const Locale('ar'));
      expect(loc.strings.appName, 'chaty');
      expect(loc.strings.chats, 'المحادثات');
      expect(loc.strings.stories, 'القصص');
      expect(loc.strings.login, 'تسجيل الدخول');
      expect(loc.strings.register, 'إنشاء حساب جديد');
      expect(loc.strings.settings, 'الإعدادات');
      expect(loc.strings.myProfile, 'ملفي الشخصي');
      expect(loc.strings.slideToCancel, 'اسحب للإلغاء');
    });

    test('English dictionary contains all essential strings', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.strings.appName, 'chaty');
      expect(loc.strings.chats, 'Chats');
      expect(loc.strings.stories, 'Stories');
      expect(loc.strings.login, 'Login');
      expect(loc.strings.register, 'Register');
      expect(loc.strings.settings, 'Settings');
      expect(loc.strings.myProfile, 'My Profile');
      expect(loc.strings.slideToCancel, 'Slide to cancel');
    });
  });
}

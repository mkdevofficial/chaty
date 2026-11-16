import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../widgets/yandex_banner_ad.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.logout),
        content: Text(strings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(strings.logout),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isArabic ? 'حول Chaty' : 'About Chaty',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'تطبيق مراسلة فورية حديث وآمن يتيح الدردشة الحية، الرسائل الصوتية، مشاركة الصور والمستندات والقصص اليومية مع تجربة مستخدم سريعة وخفيفة.'
                  : 'A modern, secure instant messaging app for real-time chat, voice notes, media sharing, and stories with a sleek and fast experience.',
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'الإصدار:' : 'Version:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        '1.0.4 (Build 5)',
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'المطور:' : 'Developer:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'MKDev',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'المنصة:' : 'Platform:',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Android (Uptodown Release)',
                        style: TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settings),
      ),
      body: ListView(
        children: [
          // Section: Appearance
          _buildSectionHeader(context, strings.appearance),

          // Theme Mode (System, Light, Dark)
          ListTile(
            leading: const Icon(Icons.brightness_medium, size: 20),
            title: Text(strings.theme, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(_getThemeModeName(themeState.themeMode, strings), style: const TextStyle(fontSize: 11.5)),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.auto_mode, size: 16),
                  tooltip: strings.themeSystem,
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 16),
                  tooltip: strings.themeLight,
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 16),
                  tooltip: strings.themeDark,
                ),
              ],
              selected: {themeState.themeMode},
              onSelectionChanged: (set) {
                themeNotifier.setThemeMode(set.first);
              },
            ),
          ),

          // Accent Colors (4 Colors)
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, size: 20),
            title: Text(strings.accentColor, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(themeState.accentColor.name, style: const TextStyle(fontSize: 11.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppAccentColor.values.map((accent) {
                final isSelected = accent == themeState.accentColor;
                return GestureDetector(
                  onTap: () => themeNotifier.setAccentColor(accent),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.seedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: accent.seedColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat Wallpaper Selector
          ListTile(
            leading: const Icon(Icons.wallpaper, size: 20),
            title: Text(strings.chatWallpaper, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(themeState.wallpaper.toUpperCase(), style: const TextStyle(fontSize: 11.5)),
            trailing: DropdownButton<String>(
              value: themeState.wallpaper,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default M3', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'doodle', child: Text('Doodle Art', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'warm', child: Text('Warm Gradient', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'dots', child: Text('Subtle Dots', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) themeNotifier.setWallpaper(val);
              },
            ),
          ),

          const Divider(height: 1),

          // Section: Language
          _buildSectionHeader(context, strings.language),
          ListTile(
            leading: const Icon(Icons.language, size: 20),
            title: Text(strings.language, style: const TextStyle(fontSize: 13.5)),
            subtitle: Text(
              themeState.locale.languageCode == 'ar'
                  ? strings.arabic
                  : strings.english,
              style: const TextStyle(fontSize: 11.5),
            ),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ar',
                  label: Text(strings.arabic, style: const TextStyle(fontSize: 11.5)),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text(strings.english, style: const TextStyle(fontSize: 11.5)),
                ),
              ],
              selected: {themeState.locale.languageCode},
              onSelectionChanged: (set) {
                themeNotifier.setLocale(Locale(set.first));
              },
            ),
          ),

          const Divider(height: 1),

          // Section: About / App Info (Clean, store-friendly, replaces raw server settings)
          _buildSectionHeader(context, isArabic ? 'عن التطبيق' : 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline, size: 20),
            title: Text(
              isArabic ? 'معلومات التطبيق' : 'App Information',
              style: const TextStyle(fontSize: 13.5),
            ),
            subtitle: const Text('Chaty v1.0.4', style: TextStyle(fontSize: 11.5)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => _showAboutDialog(context),
          ),

          const Divider(height: 1),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            title: Text(
              strings.logout,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: YandexBannerAd(),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 14, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode, dynamic strings) {
    switch (mode) {
      case ThemeMode.system:
        return strings.themeSystem;
      case ThemeMode.light:
        return strings.themeLight;
      case ThemeMode.dark:
        return strings.themeDark;
    }
  }
}

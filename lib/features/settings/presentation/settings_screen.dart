import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showServerConfigDialog(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;
    final baseController = TextEditingController(text: AppConfig.baseUrl);
    final wsController = TextEditingController(text: AppConfig.wsUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.serverConfig),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baseController,
              decoration: const InputDecoration(
                labelText: 'REST Base URL',
                hintText: 'http://185.196.20.220:5050',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: wsController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                hintText: 'ws://185.196.20.220:5050/ws',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppConfig.resetToDefault();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConfig.updateServerConfig(
                newBaseUrl: baseController.text,
                newWsUrl: wsController.text,
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(strings.save),
          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context).strings;
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
            leading: const Icon(Icons.brightness_medium),
            title: Text(strings.theme),
            subtitle: Text(_getThemeModeName(themeState.themeMode, strings)),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.auto_mode, size: 18),
                  tooltip: strings.themeSystem,
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 18),
                  tooltip: strings.themeLight,
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 18),
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
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(strings.accentColor),
            subtitle: Text(themeState.accentColor.name),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: AppAccentColor.values.map((accent) {
                final isSelected = accent == themeState.accentColor;
                return GestureDetector(
                  onTap: () => themeNotifier.setAccentColor(accent),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.seedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: accent.seedColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat Wallpaper Selector
          ListTile(
            leading: const Icon(Icons.wallpaper),
            title: Text(strings.chatWallpaper),
            subtitle: Text(themeState.wallpaper.toUpperCase()),
            trailing: DropdownButton<String>(
              value: themeState.wallpaper,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default M3')),
                DropdownMenuItem(value: 'doodle', child: Text('Doodle Art')),
                DropdownMenuItem(value: 'warm', child: Text('Warm Gradient')),
                DropdownMenuItem(value: 'dots', child: Text('Subtle Dots')),
              ],
              onChanged: (val) {
                if (val != null) themeNotifier.setWallpaper(val);
              },
            ),
          ),

          const Divider(),

          // Section: Language
          _buildSectionHeader(context, strings.language),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(strings.language),
            subtitle: Text(
              themeState.locale.languageCode == 'ar'
                  ? strings.arabic
                  : strings.english,
            ),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ar',
                  label: Text(strings.arabic),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text(strings.english),
                ),
              ],
              selected: {themeState.locale.languageCode},
              onSelectionChanged: (set) {
                themeNotifier.setLocale(Locale(set.first));
              },
            ),
          ),

          const Divider(),

          // Section: Server Configuration
          _buildSectionHeader(context, strings.serverConfig),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(strings.serverUrl),
            subtitle: Text(AppConfig.baseUrl),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showServerConfigDialog(context, ref),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              strings.logout,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
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

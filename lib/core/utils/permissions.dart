import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../localization/app_localizations.dart';

class PermissionUtils {
  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;

    final result = await Permission.microphone.request();
    if (result.isGranted) return true;

    if (context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Microphone Permission Required',
        message: 'chaty needs microphone access to record and send voice messages.',
      );
    }
    return false;
  }

  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (result.isGranted) return true;

    if (context.mounted) {
      _showPermissionDialog(
        context,
        title: 'Camera Permission Required',
        message: 'chaty needs camera access to capture photos and stories.',
      );
    }
    return false;
  }

  static Future<bool> requestPhotosPermission(BuildContext context) async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }

    // Android
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted) return true;

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final result = await Permission.photos.request();
    if (result.isGranted) return true;

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted;
  }

  static void _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final strings = AppLocalizations.of(context).strings;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
}

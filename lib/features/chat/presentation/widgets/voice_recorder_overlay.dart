import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/localization/app_localizations.dart';

class VoiceRecorderOverlay extends StatefulWidget {
  final void Function(File audioFile) onRecordingComplete;
  final VoidCallback onCancel;

  const VoiceRecorderOverlay({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<VoiceRecorderOverlay> createState() => VoiceRecorderOverlayState();
}

class VoiceRecorderOverlayState extends State<VoiceRecorderOverlay>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _timer;
  int _seconds = 0;
  String? _currentRecordingPath;
  bool _isCancelled = false;
  double _dragOffset = 0.0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        widget.onCancel();
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path;

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      });
    } catch (_) {
      widget.onCancel();
    }
  }

  Future<void> stopAndSend() async {
    _timer?.cancel();
    if (_isCancelled) return;

    try {
      final path = await _audioRecorder.stop();
      if (path != null && _seconds >= 1) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          widget.onRecordingComplete(file);
          return;
        }
      }
    } catch (_) {}
    cancel();
  }

  Future<void> cancel() async {
    _isCancelled = true;
    _timer?.cancel();
    try {
      await _audioRecorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } catch (_) {}
    widget.onCancel();
  }

  void onDragUpdate(LongPressMoveUpdateDetails details) {
    setState(() {
      _dragOffset = details.offsetFromOrigin.dx;
      // If dragged left by more than 90px -> cancel
      if (_dragOffset < -90) {
        cancel();
      }
    });
  }

  String _formatTimer(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context).strings;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // Pulsing red recording dot
          FadeTransition(
            opacity: _pulseController,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Duration timer
          Text(
            _formatTimer(_seconds),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 20),

          // Slide to cancel hint with animated chevron
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chevron_left, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  strings.slideToCancel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Cancel button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: cancel,
          ),
        ],
      ),
    );
  }
}

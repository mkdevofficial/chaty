import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../../../core/localization/app_localizations.dart';

class VoiceRecorderOverlay extends StatefulWidget {
  final void Function(File audioFile, int durationMs) onSend;
  final VoidCallback onCancel;
  final File? initialPreviewFile;
  final int? initialDurationSeconds;

  const VoiceRecorderOverlay({
    super.key,
    required this.onSend,
    required this.onCancel,
    this.initialPreviewFile,
    this.initialDurationSeconds,
  });

  @override
  State<VoiceRecorderOverlay> createState() => VoiceRecorderOverlayState();
}

class VoiceRecorderOverlayState extends State<VoiceRecorderOverlay>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  AudioPlayer? _previewPlayer;

  Timer? _timer;
  int _seconds = 0;
  String? _currentRecordingPath;
  bool _isCancelled = false;
  bool _isPreviewMode = false;
  File? _recordedFile;
  int _recordedDurationMs = 0;
  double _dragOffset = 0.0;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.initialPreviewFile != null) {
      _isPreviewMode = true;
      _recordedFile = widget.initialPreviewFile;
      _seconds = widget.initialDurationSeconds ?? 2;
      _recordedDurationMs = _seconds * 1000;
      _initPreviewPlayer();
    } else {
      _pulseController.repeat(reverse: true);
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        widget.onCancel();
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = path;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
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

  Future<void> stopRecording() async {
    _timer?.cancel();
    if (_isCancelled) return;

    try {
      final path = await _audioRecorder.stop();
      if (path != null && _seconds >= 1) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() > 0) {
          if (mounted) {
            _pulseController.stop();
            setState(() {
              _isPreviewMode = true;
              _recordedFile = file;
              _recordedDurationMs = _seconds * 1000;
            });
            await _initPreviewPlayer();
            return;
          }
        }
      }
    } catch (_) {}
    cancel();
  }

  Future<void> _initPreviewPlayer() async {
    if (_recordedFile == null) return;
    try {
      _previewPlayer ??= AudioPlayer();
      await _previewPlayer!.setFilePath(_recordedFile!.path);
    } catch (_) {}
  }

  void _sendRecording() {
    if (_recordedFile != null && _recordedFile!.existsSync()) {
      _previewPlayer?.stop();
      widget.onSend(_recordedFile!, _recordedDurationMs > 0 ? _recordedDurationMs : 1000);
    } else {
      cancel();
    }
  }

  Future<void> cancel() async {
    _isCancelled = true;
    _timer?.cancel();
    _previewPlayer?.stop();
    try {
      await _audioRecorder.stop();
      if (_recordedFile != null && _recordedFile!.existsSync()) {
        _recordedFile!.deleteSync();
      } else if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    } catch (_) {}
    widget.onCancel();
  }

  void onDragUpdate(LongPressMoveUpdateDetails details) {
    if (_isPreviewMode) return;
    setState(() {
      _dragOffset = details.offsetFromOrigin.dx;
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
    _previewPlayer?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppLocalizations.of(context).strings;

    if (_isPreviewMode) {
      return _buildPreviewBar(theme);
    }

    return Container(
      height: 60,
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
          const SizedBox(width: 16),

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

          // Cancel (delete) button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: cancel,
          ),

          // Stop recording button to go to preview
          IconButton(
            key: const Key('voice_stop_recording_button'),
            tooltip: 'Stop & Preview',
            icon: const Icon(Icons.stop_circle, color: Colors.red, size: 30),
            onPressed: stopRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBar(ThemeData theme) {
    final player = _previewPlayer;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Delete / Cancel Button
          IconButton(
            key: const Key('voice_preview_delete_button'),
            tooltip: 'Delete recording',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: cancel,
          ),

          const SizedBox(width: 4),

          // Play / Pause Button
          if (player != null)
            StreamBuilder<PlayerState>(
              stream: player.playerStateStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.playing ?? false;
                final state = snapshot.data?.processingState;
                if (state == ProcessingState.completed) {
                  player.seek(Duration.zero);
                  player.pause();
                }

                return IconButton(
                  key: const Key('voice_preview_play_button'),
                  tooltip: isPlaying ? 'Pause' : 'Play preview',
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                      player.pause();
                    } else {
                      player.play();
                    }
                  },
                );
              },
            )
          else
            const Icon(Icons.play_circle_fill, size: 32, color: Colors.grey),

          const SizedBox(width: 8),

          // Duration / progress text
          Expanded(
            child: player != null
                ? StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? Duration.zero;
                      final totalSec = _seconds > 0 ? _seconds : 1;
                      final posSec = pos.inSeconds.clamp(0, totalSec);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: posSec / totalSec,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTimer(posSec)} / ${_formatTimer(totalSec)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Text(_formatTimer(_seconds)),
          ),

          const SizedBox(width: 12),

          // Clearly Visible SEND Button
          CircleAvatar(
            key: const Key('voice_preview_send_button'),
            radius: 22,
            backgroundColor: theme.colorScheme.primary,
            child: IconButton(
              tooltip: 'Send voice note',
              icon: const Icon(Icons.send_rounded, size: 20),
              color: theme.colorScheme.onPrimary,
              onPressed: _sendRecording,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/message_model.dart';

class AudioBubble extends ConsumerStatefulWidget {
  final MessageModel message;
  final bool isOutgoing;

  const AudioBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
  });

  @override
  ConsumerState<AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends ConsumerState<AudioBubble> {
  late final AudioPlayer _player;
  bool _isInitialized = false;
  bool _hasError = false;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      if (widget.message.localFilePath != null &&
          File(widget.message.localFilePath!).existsSync()) {
        await _player.setAudioSource(
          AudioSource.file(widget.message.localFilePath!),
        );
      } else if (widget.message.attachment?.fileId != null) {
        final token = await ref.read(authStorageProvider).getToken();
        final url = AppConfig.getFileUrl(widget.message.attachment!.fileId);
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(url),
            headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_hasError) {
      await _initAudio();
      return;
    }
    if (!_isInitialized) {
      await _initAudio();
    }
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
  }

  void _toggleSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
      _player.setSpeed(_speed);
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.isOutgoing
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    final secondaryTextColor = widget.isOutgoing
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Button
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              final isBuffering =
                  playerState?.processingState == ProcessingState.buffering;

              if (_hasError) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 32,
                    color: Colors.redAccent,
                  ),
                  onPressed: _initAudio,
                );
              }

              if (isBuffering || !_isInitialized) {
                return SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  ),
                );
              }

              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  size: 38,
                  color: primaryColor,
                ),
                onPressed: _togglePlayPause,
              );
            },
          ),
          const SizedBox(width: 8),

          // Slider & Duration
          Expanded(
            child: StreamBuilder<Duration>(
              stream: _player.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.duration ??
                    Duration(
                      milliseconds: widget.message.attachment?.durationMs ?? 0,
                    );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: primaryColor.withValues(alpha: 0.3),
                        thumbColor: primaryColor,
                      ),
                      child: Slider(
                        value: position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, duration.inMilliseconds.toDouble()),
                        max: duration.inMilliseconds > 0
                            ? duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (val) {
                          _player.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(fontSize: 11, color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Speed toggle button
          InkWell(
            onTap: _toggleSpeed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_speed}x',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

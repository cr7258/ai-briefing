import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Audio player widget for briefing playback
class BriefingAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final int? duration;

  const BriefingAudioPlayer({
    super.key,
    required this.audioUrl,
    this.duration,
  });

  @override
  State<BriefingAudioPlayer> createState() => _BriefingAudioPlayerState();
}

class _BriefingAudioPlayerState extends State<BriefingAudioPlayer> {
  late AudioPlayer _player;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      await _player.setUrl(widget.audioUrl);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load audio';
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return _buildErrorView(theme);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Play button and progress
          Row(
            children: [
              _buildPlayButton(theme),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressBar(theme),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time display
          _buildTimeDisplay(theme),
        ],
      ),
    );
  }

  Widget _buildPlayButton(ThemeData theme) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        if (_isLoading || processingState == ProcessingState.loading) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            if (playing) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
            ),
            child: Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                onChanged: (value) {
                  _player.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDisplay(ThemeData theme) {
    return StreamBuilder<Duration?>(
      stream: _player.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: theme.textTheme.bodySmall,
                ),
                // Speed control
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<double>(
                      stream: _player.speedStream,
                      builder: (context, snapshot) {
                        final speed = snapshot.data ?? 1.0;
                        return TextButton(
                          onPressed: _cycleSpeed,
                          child: Text(
                            '${speed}x',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _initPlayer();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _cycleSpeed() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_player.speed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    _player.setSpeed(speeds[nextIndex]);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}


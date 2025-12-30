import 'package:flutter/material.dart' hide ThemeData, ThemeMode, Theme, Scaffold, AppBar, Card, IconButton, CircularProgressIndicator, Divider, Colors;
import 'package:just_audio/just_audio.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
        _error = '音频加载失败';
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.headphones,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '语音播报',
                  style: theme.typography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Play button and progress
            Row(
              children: [
                _buildPlayButton(theme),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildProgressBar(theme),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time display
            _buildTimeDisplay(theme),
          ],
        ),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primaryForeground,
              ),
            ),
          );
        }

        return Clickable(
          onPressed: () {
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: theme.colorScheme.primaryForeground,
              size: 28,
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
            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              children: [
                // Progress bar
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition =
                        box.globalToLocal(details.globalPosition);
                    final percentage = localPosition.dx / box.size.width;
                    final newPosition = duration * percentage;
                    _player.seek(newPosition);
                  },
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                // Speed control
                StreamBuilder<double>(
                  stream: _player.speedStream,
                  builder: (context, snapshot) {
                    final speed = snapshot.data ?? 1.0;
                    return GhostButton(
                      density: ButtonDensity.compact,
                      onPressed: _cycleSpeed,
                      child: Text(
                        '${speed}x',
                        style: theme.typography.small.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                Text(
                  _formatDuration(duration),
                  style: theme.typography.small.copyWith(
                    color: theme.colorScheme.mutedForeground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.destructive.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.destructive,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _error!,
                style: theme.typography.base.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            ),
            GhostButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initPlayer();
              },
              child: const Text('重试'),
            ),
          ],
        ),
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

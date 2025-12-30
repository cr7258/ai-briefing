import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';

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
        _error = 'Audio load failed';
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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.warning_2, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed Control
              StreamBuilder<double>(
                stream: _player.speedStream,
                builder: (context, snapshot) {
                  final speed = snapshot.data ?? 1.0;
                  return TextButton(
                    onPressed: _cycleSpeed,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    child: Text('${speed}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
              const SizedBox(width: 24),

              // Rewind
              IconButton(
                icon: const Icon(Iconsax.backward_10_seconds),
                iconSize: 32,
                onPressed: () {
                   final newPos = _player.position - const Duration(seconds: 10);
                   _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
              ),
              const SizedBox(width: 24),

              // Play/Pause
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing ?? false;

                  if (_isLoading || processingState == ProcessingState.loading) {
                    return const SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(playing ? Iconsax.pause : Iconsax.play),
                      iconSize: 32,
                      color: Colors.white,
                      onPressed: () {
                        if (playing) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),

              // Forward
              IconButton(
                icon: const Icon(Iconsax.forward_10_seconds),
                iconSize: 32,
                onPressed: () {
                   _player.seek(_player.position + const Duration(seconds: 10));
                },
              ),
              const SizedBox(width: 24),

              // More options placeholder
              IconButton(
                icon: const Icon(Iconsax.more),
                onPressed: () {},
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Progress Bar
          StreamBuilder<Duration?>(
            stream: _player.durationStream,
            builder: (context, durationSnapshot) {
              final duration = durationSnapshot.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: theme.primaryColor,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: Colors.white,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                          max: duration.inMilliseconds.toDouble(),
                          onChanged: (value) {
                            _player.seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position), style: theme.textTheme.labelSmall),
                            Text(_formatDuration(duration), style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
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

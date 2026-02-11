import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../theme/app_theme.dart';
import '../responsive/responsive.dart';

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

class _BriefingAudioPlayerState extends State<BriefingAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _pulseController;
  bool _isLoading = true;
  String? _error;

  // Generate waveform data for visualization
  late List<double> _waveformData;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Generate pseudo-random waveform data
    final random = Random(widget.audioUrl.hashCode);
    _waveformData = List.generate(50, (i) {
      final base = sin((i / 50) * pi * 2) * 0.3 + 0.5;
      return (base + random.nextDouble() * 0.4).clamp(0.15, 1.0);
    });
    
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorState();
    }

    final padding = Responsive.cardPadding(context);
    final spacing = Responsive.sectionSpacing(context);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Waveform Visualization
          _buildWaveformProgress(context),
          
          SizedBox(height: spacing),
          
          // Time Display
          _buildTimeDisplay(),
          
          SizedBox(height: spacing),
          
          // Controls Row
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: AppTheme.error, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audio Unavailable',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(
                    color: AppTheme.error.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _error = null;
                _isLoading = true;
              });
              _initPlayer();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformProgress(BuildContext parentContext) {
    final waveformHeight = Responsive.waveformHeight(parentContext);
    
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

            return StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, stateSnapshot) {
                final isPlaying = stateSnapshot.data?.playing ?? false;
                
                return GestureDetector(
                  onTapDown: (details) {
                    if (duration.inMilliseconds > 0) {
                      final box = context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(details.globalPosition);
                      final percentage = localPosition.dx / box.size.width;
                      _player.seek(duration * percentage.clamp(0.0, 1.0));
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      height: waveformHeight,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _WaveformPainter(
                          waveformData: _waveformData,
                          progress: progress,
                          isPlaying: isPlaying,
                          pulseAnimation: _pulseController,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTimeDisplay() {
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
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Remaining time
                    Text(
                      '-${_formatDuration(duration - position)}',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildSpeedControl(),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls(BuildContext parentContext) {
    final playBtnSize = Responsive.playButtonSize(parentContext);
    final ctrlBtnSize = Responsive.controlButtonSize(parentContext);
    final isMobile = Responsive.isMobile(parentContext);
    final spacing = isMobile ? 12.0 : 16.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind 15s
        _ControlButton(
          icon: Iconsax.backward_15_seconds,
          size: ctrlBtnSize,
          onTap: () {
            final newPos = _player.position - const Duration(seconds: 15);
            _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
          },
        ),
        
        SizedBox(width: spacing - 4),
        
        // Play/Pause Button
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;

            if (_isLoading || processingState == ProcessingState.loading) {
              return Container(
                width: playBtnSize,
                height: playBtnSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.black,
                    ),
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
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = playing ? 1.0 + _pulseController.value * 0.05 : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: playBtnSize,
                      height: playBtnSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.primary, AppTheme.primaryAlt],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(playing ? 0.5 : 0.3),
                            blurRadius: playing ? 20 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        playing ? Iconsax.pause : Iconsax.play,
                        color: Colors.black,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        SizedBox(width: spacing - 4),
        
        // Forward 15s
        _ControlButton(
          icon: Iconsax.forward_15_seconds,
          size: ctrlBtnSize,
          onTap: () {
            _player.seek(_player.position + const Duration(seconds: 15));
          },
        ),
        
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildSpeedControl() {
    return StreamBuilder<double>(
      stream: _player.speedStream,
      builder: (context, snapshot) {
        final speed = snapshot.data ?? 1.0;
        return PopupMenuButton<double>(
          onSelected: (value) => _player.setSpeed(value),
          offset: const Offset(0, -240),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.border),
          ),
          color: AppTheme.surfaceVariant,
          itemBuilder: (context) => [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
              .map((s) => PopupMenuItem<double>(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          child: s == speed
                              ? const Icon(Icons.check, size: 16, color: AppTheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${s}x',
                          style: TextStyle(
                            color: s == speed ? AppTheme.primary : AppTheme.textSecondary,
                            fontWeight: s == speed ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '${speed}x',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.border),
        ),
        child: Icon(
          icon,
          color: AppTheme.textSecondary,
          size: size * 0.45,
        ),
      ),
    );
  }
}

/// Custom painter for audio waveform visualization
class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final double progress;
  final bool isPlaying;
  final Animation<double> pulseAnimation;

  _WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.isPlaying,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = waveformData.length;
    final barWidth = (size.width / barCount) - 2;
    final maxHeight = size.height;
    
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + 2) + barWidth / 2;
      final barProgress = i / barCount;
      final isPast = barProgress <= progress;
      
      // Calculate bar height with optional pulse effect
      var heightFactor = waveformData[i];
      if (isPlaying && isPast && barProgress > progress - 0.05) {
        heightFactor *= 1.0 + pulseAnimation.value * 0.3;
      }
      final barHeight = maxHeight * heightFactor.clamp(0.15, 1.0);
      
      final paint = Paint()
        ..strokeWidth = barWidth.clamp(2.0, 4.0)
        ..strokeCap = StrokeCap.round;
      
      if (isPast) {
        // Gradient for played portion
        paint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppTheme.primary,
            AppTheme.primary.withOpacity(0.6),
          ],
        ).createShader(Rect.fromLTWH(x - barWidth / 2, (size.height - barHeight) / 2, barWidth, barHeight));
      } else {
        paint.color = AppTheme.border;
      }
      
      // Draw bar centered vertically
      final y = (size.height - barHeight) / 2;
      canvas.drawLine(
        Offset(x, y + barHeight),
        Offset(x, y),
        paint,
      );
    }
    
    // Draw playhead indicator
    if (progress > 0 && progress < 1) {
      final playheadX = size.width * progress;
      final playheadPaint = Paint()
        ..color = AppTheme.textPrimary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      
      canvas.drawLine(
        Offset(playheadX, 0),
        Offset(playheadX, size.height),
        playheadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.isPlaying != isPlaying;
  }
}

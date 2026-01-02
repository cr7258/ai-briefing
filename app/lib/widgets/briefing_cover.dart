import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Premium "Album Art" style cover with audio waveform visualization
/// Gives the app a Spotify/Podcast player aesthetic
class BriefingCover extends StatelessWidget {
  final DateTime date;
  final double size;
  final bool showTitle;
  final bool showWaveform;

  const BriefingCover({
    super.key,
    required this.date,
    this.size = 120,
    this.showTitle = true,
    this.showWaveform = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate consistent gradient based on date
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    
    // Curated color palettes (more premium than random)
    final palettes = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)], // Purple Blue
      [const Color(0xFF1ED760), const Color(0xFF1DB954)], // Spotify Green
      [const Color(0xFF00D4FF), const Color(0xFF7C3AED)], // Cyan Purple
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)], // Coral Orange
      [const Color(0xFF4158D0), const Color(0xFFC850C0)], // Blue Pink
      [const Color(0xFF0F2027), const Color(0xFF2C5364)], // Deep Ocean
      [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], // Pink Blue
    ];
    
    final palette = palettes[seed % palettes.length];

    // Format date for the cover
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM').format(date).toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        borderRadius: BorderRadius.circular(size > 200 ? 24 : 16),
        boxShadow: [
          BoxShadow(
            color: palette[0].withOpacity(0.4),
            blurRadius: size > 200 ? 40 : 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size > 200 ? 24 : 16),
      child: Stack(
        children: [
            // Noise texture overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _NoisePainter(
                  opacity: 0.03,
                  seed: seed,
                ),
              ),
            ),
            
            // Subtle mesh gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Audio waveform visualization
            if (showWaveform)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size * 0.4,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    seed: seed,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            
            // Dark gradient at bottom for readability
            if (showTitle)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size * 0.6,
                child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                        Colors.black.withOpacity(0.5),
                ],
              ),
                  ),
            ),
          ),
          
            // Date display
          if (showTitle)
              Positioned(
                left: size > 200 ? 24 : 12,
                bottom: size > 200 ? 24 : 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                      style: TextStyle(
                      color: Colors.white,
                        fontSize: size > 200 ? 48 : (size > 100 ? 32 : 24),
                        fontWeight: FontWeight.w800,
                      height: 1.0,
                        letterSpacing: -1,
                    ),
                  ),
                  Text(
                    month,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: size > 200 ? 16 : (size > 100 ? 12 : 10),
                        fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            
            // AI Badge
          Positioned(
              top: size > 200 ? 20 : 10,
              right: size > 200 ? 20 : 10,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size > 200 ? 12 : 8,
                  vertical: size > 200 ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
              Icons.auto_awesome,
                      color: Colors.white.withOpacity(0.9),
                      size: size > 200 ? 14 : 10,
                    ),
                    SizedBox(width: size > 200 ? 6 : 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: size > 200 ? 11 : 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
            ),
          ),
        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for subtle noise texture
class _NoisePainter extends CustomPainter {
  final double opacity;
  final int seed;

  _NoisePainter({
    required this.opacity,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint();
    
    // Draw subtle noise dots
    for (int i = 0; i < 500; i++) {
      paint.color = (random.nextBool() ? Colors.white : Colors.black)
          .withOpacity(opacity * random.nextDouble());
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() * 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for audio waveform visualization
class _WaveformPainter extends CustomPainter {
  final int seed;
  final Color color;

  _WaveformPainter({
    required this.seed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const barCount = 40;
    final barWidth = size.width / barCount;
    final maxHeight = size.height * 0.8;

    for (int i = 0; i < barCount; i++) {
      // Generate varying heights that look like audio waveform
      final heightFactor = sin((i / barCount) * pi * 2 + random.nextDouble() * 2) * 0.5 + 0.5;
      final randomFactor = random.nextDouble() * 0.4 + 0.3;
      final barHeight = maxHeight * heightFactor * randomFactor;
      
      final x = i * barWidth + barWidth / 2;
      final y = size.height - barHeight;
      
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  }

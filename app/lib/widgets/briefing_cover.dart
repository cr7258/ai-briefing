import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// A widget that generates a unique "Album Art" based on the date.
/// Gives the app a premium Podcast/Music player feel.
class BriefingCover extends StatelessWidget {
  final DateTime date;
  final double size;
  final bool showTitle;

  const BriefingCover({
    super.key,
    required this.date,
    this.size = 120,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a consistent deterministic gradient based on the date
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = Random(seed);
    
    // Pick 2 random vibrant colors
    final colors = [
      _getRandomColor(random),
      _getRandomColor(random),
    ];

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
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Noise/Texture overlay (simulated with gradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          if (showTitle)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            
          // AI Icon badge
          Positioned(
            bottom: 8,
            right: 8,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRandomColor(Random random) {
    final hue = random.nextDouble() * 360;
    final saturation = 0.6 + random.nextDouble() * 0.4; // 0.6 - 1.0
    final lightness = 0.4 + random.nextDouble() * 0.2; // 0.4 - 0.6
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
}


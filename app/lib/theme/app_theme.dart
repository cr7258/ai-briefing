import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // OLED Dark Mode + Audio Waveform Inspired Colors
  // Based on: Dark Mode (OLED) + Podcast Platform recommendations
  
  // Background colors - True OLED Black
  static const Color background = Color(0xFF000000); // Pure OLED black
  static const Color surface = Color(0xFF0A0A0A); // Slightly lighter for cards
  static const Color surfaceVariant = Color(0xFF141414); // Card hover state
  static const Color surfaceElevated = Color(0xFF1A1A1A); // Elevated surfaces
  
  // Primary - Audio Waveform Blue (Spotify-inspired)
  static const Color primary = Color(0xFF1ED760); // Vibrant green (Spotify style)
  static const Color primaryAlt = Color(0xFF1DB954); // Darker green
  
  // Alternative: Cyan/Blue gradient for AI feel
  static const Color accent = Color(0xFF00D4FF); // Neon Cyan
  static const Color accentPurple = Color(0xFF7C3AED); // Electric Purple
  
  // Semantic colors
  static const Color error = Color(0xFFFF4757); // Soft red
  static const Color warning = Color(0xFFFFBE0B); // Amber
  static const Color success = Color(0xFF1ED760); // Same as primary
  
  // Text colors - High contrast for OLED
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white for main text
  static const Color textSecondary = Color(0xFFB3B3B3); // 70% white
  static const Color textTertiary = Color(0xFF727272); // 45% white
  static const Color textMuted = Color(0xFF535353); // Very muted

  // Border colors
  static const Color border = Color(0xFF282828); // Subtle border
  static const Color borderLight = Color(0xFF404040); // Visible border

  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildDarkTheme() {
    final textTheme = _buildTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        tertiary: accentPurple,
        surface: surface,
        surfaceContainerHighest: surfaceVariant,
        error: error,
        onSurface: textPrimary,
        onPrimary: Color(0xFF000000), // Black text on primary
        outline: border,
        outlineVariant: borderLight,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: textPrimary,
        unselectedItemColor: textTertiary,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          padding: const EdgeInsets.all(12),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: border,
        thumbColor: textPrimary,
        overlayColor: primary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6,
          pressedElevation: 8,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),

      // Text Theme
      textTheme: textTheme,
    );
  }

  static TextTheme _buildTextTheme() {
    // Space Grotesk for headings (tech, futuristic, bold)
    // DM Sans for body (highly readable, modern)
    return TextTheme(
      // Display styles - Space Grotesk
      displayLarge: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.0,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
        height: 1.2,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      
      // Title styles - DM Sans
      titleLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.dmSans(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      
      // Body styles - DM Sans (highly readable)
      bodyLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.65,
        letterSpacing: 0.1,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        color: textTertiary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.dmSans(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelMedium: GoogleFonts.dmSans(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.dmSans(
        color: textTertiary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

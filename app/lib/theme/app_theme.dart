import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // One Dark Pro Inspired Colors
  static const Color background = Color(0xFF282C34); // One Dark Pro Background
  static const Color surface = Color(0xFF21252B); // Darker surface for sidebars/panels
  static const Color surfaceVariant = Color(0xFF333842); // Slightly lighter for cards
  
  static const Color primary = Color(0xFF61AFEF); // One Dark Blue
  static const Color accent = Color(0xFF98C379); // One Dark Green
  static const Color error = Color(0xFFE06C75); // One Dark Red
  static const Color warning = Color(0xFFE5C07B); // One Dark Yellow
  static const Color secondary = Color(0xFFC678DD); // One Dark Purple

  static const Color textPrimary = Color(0xFFABB2BF); // Standard text color (not pure white)
  static const Color textSecondary = Color(0xFF7F848E); // Comment color for secondary text
  static const Color textTertiary = Color(0xFF5C6370); // Darker comment color

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onSurface: textPrimary,
        onPrimary: Color(0xFF282C34), // Dark text on primary buttons
        outline: textTertiary,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.zero,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary, // Main body text
          fontSize: 16,
          height: 1.6, // Slightly increased line height for readability
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary, // Secondary info
          fontSize: 14,
          height: 1.5,
        ),
        labelSmall: GoogleFonts.inter(
          color: textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: surface,
        thickness: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Responsive utilities for adapting UI to different screen sizes
class Responsive {
  /// Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Responsive value based on screen size
  /// Returns [mobile] for phones, [tablet] for tablets, [desktop] for desktop
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= tabletBreakpoint) {
      return desktop ?? tablet ?? mobile;
    } else if (width >= mobileBreakpoint) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  /// Responsive padding
  static EdgeInsets padding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 20),
      tablet: const EdgeInsets.symmetric(horizontal: 32),
      desktop: const EdgeInsets.symmetric(horizontal: 48),
    );
  }

  /// Detail screen cover size
  static double detailCoverSize(BuildContext context) {
    return value(
      context,
      mobile: 180.0,
      tablet: 240.0,
      desktop: 280.0,
    );
  }

  /// Hero card height
  static double heroCardHeight(BuildContext context) {
    return value(
      context,
      mobile: 380.0,
      tablet: 420.0,
      desktop: 450.0,
    );
  }

  /// Play button size
  static double playButtonSize(BuildContext context) {
    return value(
      context,
      mobile: 60.0,
      tablet: 68.0,
      desktop: 72.0,
    );
  }

  /// Control button size
  static double controlButtonSize(BuildContext context) {
    return value(
      context,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 52.0,
    );
  }

  /// Waveform height
  static double waveformHeight(BuildContext context) {
    return value(
      context,
      mobile: 44.0,
      tablet: 56.0,
      desktop: 64.0,
    );
  }

  /// Card padding
  static double cardPadding(BuildContext context) {
    return value(
      context,
      mobile: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );
  }

  /// Section spacing
  static double sectionSpacing(BuildContext context) {
    return value(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }

  /// Max content width for centered layouts on large screens
  static double maxContentWidth(BuildContext context) {
    return value(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
    );
  }
}

/// Extension for easier access
extension ResponsiveContext on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  double get screenWidth => Responsive.screenWidth(this);
  double get screenHeight => Responsive.screenHeight(this);
}


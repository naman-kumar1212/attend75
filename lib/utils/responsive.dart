import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

/// Phone size classification for responsive UI
enum PhoneSize {
  small, // < 360dp width (compact phones)
  medium, // 360-400dp width (standard phones)
  large, // > 400dp width (large phones, phablets)
}

class Responsive {
  static DeviceType deviceType(BuildContext context) {
    return DeviceType.mobile;
  }

  static bool isMobile(BuildContext context) => true;

  static bool isTablet(BuildContext context) => false;

  static bool isDesktop(BuildContext context) => false;

  /// Get phone size classification based on screen width
  static PhoneSize phoneSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return PhoneSize.small;
    if (width < 400) return PhoneSize.medium;
    return PhoneSize.large;
  }

  /// Check if small phone
  static bool isSmallPhone(BuildContext context) =>
      phoneSize(context) == PhoneSize.small;

  /// Check if medium phone
  static bool isMediumPhone(BuildContext context) =>
      phoneSize(context) == PhoneSize.medium;

  /// Check if large phone
  static bool isLargePhone(BuildContext context) =>
      phoneSize(context) == PhoneSize.large;

  /// Get value based on phone size
  static T phoneValue<T>(
    BuildContext context, {
    required T small,
    T? medium,
    T? large,
  }) {
    final size = phoneSize(context);
    switch (size) {
      case PhoneSize.small:
        return small;
      case PhoneSize.medium:
        return medium ?? small;
      case PhoneSize.large:
        return large ?? medium ?? small;
    }
  }

  /// Example helper for returning value based on device type
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return mobile;
  }
}

class ResponsiveValues {
  final BuildContext context;
  ResponsiveValues(this.context);
  bool get isMobile => Responsive.isMobile(context);
  bool get isTablet => Responsive.isTablet(context);
  bool get isDesktop => Responsive.isDesktop(context);
  DeviceType get deviceType => Responsive.deviceType(context);

  EdgeInsets get pagePadding => isDesktop
      ? const EdgeInsets.all(32)
      : isTablet
      ? const EdgeInsets.all(24)
      : const EdgeInsets.all(20); // 20px horizontal/vertical for mobile

  EdgeInsets get contentPaddingWithNav {
    // Pages handle their own top padding (content extends behind glass header)
    // Use viewPadding.top to get real status bar height
    // Design buffer: 24dp for visual breathing room below glass header
    final topPadding =
        kToolbarHeight + MediaQuery.of(context).viewPadding.top + 64;
    // Bottom: device safe area + navbar height (approx 80dp) + extra spacing
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = bottomSafeArea + 80 + 16; // navbar + spacing
    return pagePadding.copyWith(top: topPadding, bottom: bottomPadding);
  }

  /// Bottom padding for content that sits above the bottom navbar
  /// Uses actual device insets for cross-device compatibility
  double get bottomNavPadding {
    final bottomSafeArea = MediaQuery.of(context).viewPadding.bottom;
    return bottomSafeArea + 80 + 16; // navbar height + safe area + spacing
  }

  double get spacing => isDesktop ? 24 : 16;

  double get ringSize => isDesktop
      ? 260
      : isTablet
      ? 200
      : 140;

  // Dynamic column count based on item width
  int getAdaptiveGridColumns(double itemWidth) {
    double screenWidth = MediaQuery.of(context).size.width;
    // Adjust for sidebar/rail if needed, but simple width check is okay for now
    if (isDesktop) screenWidth -= 256; // Approximate sidebar width
    if (isTablet) screenWidth -= 72; // Approximate rail width
    int columns = (screenWidth / itemWidth).floor();
    return columns > 0 ? columns : 1;
  }

  // Deprecated-style grid columns helper
  int getGridColumns({required int mobile, int? tablet, int? desktop}) {
    return value<int>(mobile: mobile, tablet: tablet, desktop: desktop);
  }

  T value<T>({required T mobile, T? tablet, T? desktop}) {
    return Responsive.value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

extension ResponsiveExtension on BuildContext {
  ResponsiveValues get responsive => ResponsiveValues(this);
}

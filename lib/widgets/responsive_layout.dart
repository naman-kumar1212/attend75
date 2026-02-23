import 'package:flutter/material.dart';

/// Responsive breakpoints for desktop adaptation.
/// These values follow common web/desktop conventions:
/// - Mobile: < 600px (phones, small windows)
/// - Tablet: 600px - 1199px (tablets, medium windows)
/// - Desktop: >= 1200px (laptops, desktops)
/// - Widescreen: >= 1800px (large monitors)
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1800;

  // Prevent instantiation
  ResponsiveBreakpoints._();
}

/// A widget that selects between different layouts based on screen width.
///
/// Provides [mobile], [tablet], and [desktop] layouts with automatic
/// fallback to simpler layouts when more complex ones aren't provided.
class ResponsiveLayout extends StatelessWidget {
  /// Layout for mobile screens (< 600px)
  final Widget mobile;

  /// Layout for tablet screens (600px - 1199px). Falls back to [mobile] if null.
  final Widget? tablet;

  /// Layout for desktop screens (>= 1200px). Falls back to [tablet] or [mobile] if null.
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Check if current screen width is mobile-sized (< 600px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  /// Check if current screen width is tablet-sized (600px - 1199px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.mobile &&
        width < ResponsiveBreakpoints.desktop;
  }

  /// Check if current screen width is desktop-sized (>= 1200px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  /// Check if current screen width is widescreen (>= 1800px)
  static bool isWidescreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.widescreen;

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isWidescreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 64);
    } else if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 48);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// Get max content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    if (isWidescreen(context)) return 1400;
    if (isDesktop(context)) return 1200;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Desktop layout (if provided and screen is large enough)
    if (width >= ResponsiveBreakpoints.desktop && desktop != null) {
      return desktop!;
    }

    // Tablet layout (if provided and screen is medium)
    if (width >= ResponsiveBreakpoints.mobile && tablet != null) {
      return tablet!;
    }

    // Default to mobile layout
    return mobile;
  }
}

/// Wrapper widget that constrains content width and centers it on large screens.
/// Use this for page content that shouldn't span the full width on desktop.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveLayout.getMaxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? ResponsiveLayout.getHorizontalPadding(context),
          child: child,
        ),
      ),
    );
  }
}

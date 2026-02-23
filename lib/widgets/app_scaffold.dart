import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'app_menu_drawer.dart';
import 'responsive_layout.dart';

/// Navigation items configuration for consistent use across layouts
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

const List<_NavItem> _navItems = [
  _NavItem(LucideIcons.home, 'Home'),
  _NavItem(LucideIcons.barChart3, 'Dashboard'),
  _NavItem(LucideIcons.bookOpen, 'Subjects'),
  _NavItem(LucideIcons.clock, 'Duty Leave'),
  _NavItem(LucideIcons.settings, 'Settings'),
];

class AppScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigationChanged;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  // Track hover state for NavigationRail items
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // Use responsive layout to switch between mobile and desktop
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildDesktopLayout(context), // Tablet uses NavigationRail too
      desktop: _buildDesktopLayout(context),
    );
  }

  // ============================================
  // MOBILE LAYOUT (BottomNavigationBar)
  // ============================================

  Widget _buildMobileLayout(BuildContext context) {
    // Content extends behind glass header (no Padding wrapper here)
    // Pages handle their own top padding to push visible content below header
    // This allows glass blur to sample actual page content
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      extendBody: true, // Crucial for glass effect
      appBar: _buildGlassAppBar(context),
      body: widget.child, // Direct pass-through, no wrapper
      bottomNavigationBar: _buildGlassNavigationBar(context),
    );
  }

  // ============================================
  // DESKTOP LAYOUT (NavigationRail + AppBar)
  // ============================================

  Widget _buildDesktopLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildDesktopAppBar(context),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // NavigationRail on the left
          _buildNavigationRail(context, isDark, colorScheme),

          // Vertical divider for visual separation
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),

          // Main content area
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Text(
        'Attend 75',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu, color: colorScheme.onSurface),
            onPressed: () => _openMenu(context),
            tooltip: 'Open menu',
          ),
        ),
        const SizedBox(width: 16),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.55);
    final hoverColor = colorScheme.primary.withValues(alpha: 0.08);

    return Container(
      width: 80,
      color: isDark
          ? colorScheme.surface.withValues(alpha: 0.5)
          : colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Navigation items
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = widget.currentIndex == index;
            final isHovered = _hoveredIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onNavigationChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      // User requested to remove the background color on selected items
                      // and only show the colored icon/text.
                      color: isHovered ? hoverColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          child: Icon(
                            item.icon,
                            color: isSelected
                                ? selectedColor
                                : isHovered
                                ? colorScheme.onSurface
                                : unselectedColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected
                                ? selectedColor
                                : isHovered
                                ? colorScheme.onSurface
                                : unselectedColor,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================
  // SHARED COMPONENTS (Mobile)
  // ============================================

  PreferredSizeWidget _buildGlassAppBar(BuildContext context) {
    // Determine the base color for the glass effect based on the theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBaseColor = isDark ? Colors.black : Colors.white;
    final tintColor = Theme.of(context).scaffoldBackgroundColor;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      // System overlay style for status bar icons visibility
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      title: Text(
        'Attend 75',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(
              LucideIcons.menu,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _openMenu(context),
            tooltip: 'Open menu',
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: ClipRect(
        // Rectangular clipping (BorderRadius.zero implied)
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              // Vertical gradient: 0.08 top -> 0.02 bottom
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  glassBaseColor.withValues(alpha: 0.08),
                  glassBaseColor.withValues(alpha: 0.02),
                ],
              ),
              // Tint for text legibility
              color: tintColor.withValues(alpha: 0.10),
              // Bottom border for visual separation
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              // Subtle shadow for depth
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavigationBar(BuildContext context) {
    // Determine the base color for the glass effect based on the theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark mode: Glass effect with blur and gradient
    // Light mode: Pure white background for consistency
    final glassBaseColor = isDark ? Colors.black : Colors.white;

    return Container(
      height:
          72 +
          MediaQuery.of(
            context,
          ).padding.bottom, // 72 logical pixels + safe area
      decoration: BoxDecoration(
        color: Colors.transparent,
        // No border radius (Rectangular)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: isDark ? 20 : 10,
            offset: const Offset(0, -4), // Upward shadow
          ),
        ],
      ),
      child: ClipRect(
        // Use ClipRect for rectangular clipping
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isDark ? 18 : 0, // No blur in light mode for pure white
            sigmaY: isDark ? 18 : 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              // Dark mode: Original glass gradient + tint
              // Light mode: Pure solid white
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        glassBaseColor.withValues(alpha: 0.08),
                        glassBaseColor.withValues(alpha: 0.02),
                      ],
                    )
                  : null,
              color: isDark
                  ? Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.10)
                  : Colors.white, // Pure white for light mode
            ),
            child: SafeArea(
              bottom: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _navItems.length,
                  (index) => _buildMobileNavItem(
                    context,
                    index,
                    _navItems[index].icon,
                    _navItems[index].label,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = widget.currentIndex == index;
    // Theme-aware colors
    // Use primary color (Accent Color) for selected state as per user request
    final selectedColor = Theme.of(context).colorScheme.primary;
    final unselectedColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onNavigationChanged(index),
        child: SizedBox(
          height: double.infinity, // Fill height
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? selectedColor : unselectedColor,
                  fontSize: 12, // 12-13 range
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // MENU DIALOG (Shared)
  // ============================================

  void _openMenu(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final topOffset = topPadding + kToolbarHeight;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            // Desktop: No top offset since AppBar is not transparent
            padding: EdgeInsets.only(
              top: isDesktop ? 0 : topOffset,
              bottom: bottomInset,
            ),
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 400
                  ? 360
                  : MediaQuery.of(context).size.width * 0.85,
              child: const AppMenuDrawer(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve)),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }
} // End of AppScaffold

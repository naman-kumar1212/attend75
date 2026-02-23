import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../utils/theme.dart';
import '../pages/auth/sign_in_page.dart';
import '../pages/auth/sign_up_page.dart';
import '../utils/snackbar_helper.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glass effect colors matching navbar/footer
    final glassBaseColor = isDark ? Colors.black : Colors.white;
    final tintColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: BackdropFilter(
        // Blur only for dark mode, no blur for light mode (pure white)
        filter: ImageFilter.blur(
          sigmaX: isDark ? 18 : 0,
          sigmaY: isDark ? 18 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            // Dark mode: Glass gradient with blur effect
            // Light mode: Pure solid white
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      glassBaseColor.withValues(alpha: 0.85),
                      glassBaseColor.withValues(alpha: 0.70),
                    ],
                  )
                : null,
            // Dark mode: tint for legibility
            // Light mode: pure white
            color: isDark ? tintColor.withValues(alpha: 0.12) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
            // Left border for visual separation
            border: Border(
              left: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            // Subtle shadow for depth
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: isDark ? 24 : 16,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                // User Header - Theme-aware, no accent background
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return _buildHeader(
                      context,
                      authProvider,
                      colorScheme,
                      isDark,
                      surfaceColor,
                    );
                  },
                ),

                // Soft divider between header and content
                _buildGlassDivider(colorScheme),

                // Body content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      // Auth / Profile Actions
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          // Authenticated user - show Profile
                          if (authProvider.isSignedIn &&
                              !authProvider.isGuest) {
                            return _buildMenuItem(
                              context: context,
                              icon: LucideIcons.user,
                              title: 'Profile',
                              colorScheme: colorScheme,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.of(context).pushNamed('/profile');
                              },
                            );
                          } else {
                            // Guest user or not signed in - show Sign In/Sign Up options
                            return Column(
                              children: [
                                _buildMenuItem(
                                  context: context,
                                  icon: LucideIcons.logIn,
                                  title: 'Sign In',
                                  colorScheme: colorScheme,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignInPage(),
                                      ),
                                    );
                                  },
                                ),
                                _buildMenuItem(
                                  context: context,
                                  icon: LucideIcons.userPlus,
                                  title: 'Sign Up',
                                  colorScheme: colorScheme,
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignUpPage(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      // Subtle section divider
                      _buildSectionDivider(colorScheme),

                      // Appearance Section
                      _buildSectionLabel(context, 'Appearance', colorScheme),

                      SwitchListTile(
                        secondary: Icon(
                          // Use actual brightness from context, not themeProvider.isDarkMode
                          // This ensures icon matches the actual rendered theme
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        // Use actual brightness to show current state
                        value: isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                      ),

                      _buildSectionLabel(context, 'Accent Color', colorScheme),

                      // Horizontal Scrollable Color Picker
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: AppTheme.accentColors.map((preset) {
                            final color = preset['color'] as Color;
                            final isSelected =
                                themeProvider.accentColor.toARGB32() ==
                                color.toARGB32();

                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _ColorSwatch(
                                color: color,
                                isSelected: isSelected,
                                onTap: () =>
                                    themeProvider.setAccentColor(color),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      _buildSectionDivider(colorScheme),

                      _buildMenuItem(
                        context: context,
                        icon: LucideIcons.helpCircle,
                        title: 'Help & Support',
                        colorScheme: colorScheme,
                        onTap: () {
                          Navigator.pop(context);
                          SnackbarHelper.show(
                            context,
                            'Help center coming soon!',
                            icon: LucideIcons.info,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Footer
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    // Authenticated non-guest user - show Sign Out
                    if (authProvider.isSignedIn && !authProvider.isGuest) {
                      return Column(
                        children: [
                          _buildSectionDivider(colorScheme),
                          ListTile(
                            leading: Icon(
                              LucideIcons.logOut,
                              color: colorScheme.error,
                            ),
                            title: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () async {
                              // Clear local data before signing out
                              await context
                                  .read<AttendanceProvider>()
                                  .clearLocalData();
                              await authProvider.signOut();
                              if (context.mounted) {
                                Navigator.pop(context);
                                SnackbarHelper.show(
                                  context,
                                  'Signed out successfully',
                                  icon: LucideIcons.logOut,
                                );
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              "v1.0.0",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Not signed in at all - just show version
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "v1.0.0",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with theme-aware styling (no accent background)
  Widget _buildHeader(
    BuildContext context,
    AuthProvider authProvider,
    ColorScheme colorScheme,
    bool isDark,
    Color surfaceColor,
  ) {
    if (authProvider.isSignedIn && !authProvider.isGuest) {
      final initials = authProvider.initials;
      final fullName = authProvider.fullName;
      final email = authProvider.email;
      final avatarUrl = authProvider.avatarUrl;

      // Loading state
      if (authProvider.isProfileLoading) {
        return _buildHeaderContainer(
          context: context,
          colorScheme: colorScheme,
          surfaceColor: surfaceColor,
          child: Row(
            children: [
              // Skeleton avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton name
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Skeleton email
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      // Signed in state
      return _buildHeaderContainer(
        context: context,
        colorScheme: colorScheme,
        surfaceColor: surfaceColor,
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).pushNamed('/profile');
        },
        child: Row(
          children: [
            // Avatar
            _buildAvatar(
              avatarUrl: avatarUrl,
              initials: initials,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isNotEmpty ? fullName : 'User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Chevron indicator
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      );
    } else {
      // Guest state
      return _buildHeaderContainer(
        context: context,
        colorScheme: colorScheme,
        surfaceColor: surfaceColor,
        child: Row(
          children: [
            // Guest avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.user,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to sync your data',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildHeaderContainer({
    required BuildContext context,
    required ColorScheme colorScheme,
    required Color surfaceColor,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return SafeArea(
      bottom: false,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
          child: child,
        ),
      ),
    );
  }

  /// Build avatar with proper fallback to initials (NEVER "?")
  Widget _buildAvatar({
    required String? avatarUrl,
    required String initials,
    required ColorScheme colorScheme,
  }) {
    // Ensure initials are never empty or "?"
    final displayInitials = (initials.isNotEmpty && initials != '?')
        ? initials
        : 'U'; // Fallback to 'U' for User

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? (avatarUrl.startsWith('http')
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          _buildInitialsAvatar(displayInitials, colorScheme),
                    )
                  : Image.file(
                      File(avatarUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) =>
                          _buildInitialsAvatar(displayInitials, colorScheme),
                    ))
            : _buildInitialsAvatar(displayInitials, colorScheme),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, ColorScheme colorScheme) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        // Use onSurface with slight transparency for unselected state to ensure good contrast
        // on glass background (onSurfaceVariant can be too faint)
        color: isActive
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.75),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      // Subtle active indicator using accent color
      selected: isActive,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
    );
  }

  Widget _buildSectionDivider(ColorScheme colorScheme) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colorScheme.outline.withValues(alpha: 0.15),
            colorScheme.outline.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ),
      ),
    );
  }

  /// Glass-style divider for header separation
  Widget _buildGlassDivider(ColorScheme colorScheme) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            colorScheme.outline.withValues(alpha: 0.20),
            colorScheme.outline.withValues(alpha: 0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.1, 0.9, 1.0],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(
    BuildContext context,
    String label,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Subtle border on all swatches for visibility
          border: Border.all(
            color: isSelected
                ? colorScheme.onSurface
                : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.15)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            // Base subtle shadow for depth
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(LucideIcons.check, color: _getContrastColor(color), size: 20)
            : null,
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

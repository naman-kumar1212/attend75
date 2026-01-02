import 'package:flutter/material.dart';

// Theme configuration matching React app's design system
// All colors converted from HSL to RGB to match index.css
class AppTheme {
  // Primary: Teal/Green accent from mockup
  static const Color primaryColor = Color(
    0xFF2F8F85,
  ); // Updated to match mockup
  static const Color primaryLight = Color(0xFF4FADA3);
  static const Color primaryDark = Color(0xFF1F7A70);

  // Secondary/Accent: HSL(260, 30%, 65%) -> Lavender
  static const Color secondaryColor = Color(0xFF9580C4);
  static const Color secondaryLight = Color(0xFFB8A5E5);
  static const Color secondaryDark = Color(0xFF6B5B9A);

  // Status colors matching CSS variables
  static const Color successColor = Color(0xFF20B566); // HSL(140, 75%, 45%)
  static const Color warningColor = Color(0xFFFFC107); // HSL(45, 95%, 55%)
  static const Color errorColor = Color(0xFFE85D4D); // HSL(0, 75%, 60%)

  // Defined Accent Colors
  static const List<Map<String, dynamic>> accentColors = [
    {'name': 'Teal', 'color': Color(0xFF1CB5AD)}, // HSL(175, 75%, 45%)
    {'name': 'Orange', 'color': Color(0xFFFA6432)}, // HSL(25, 95%, 53%)
    {'name': 'Blue', 'color': Color(0xFF3B82F6)}, // HSL(217, 91%, 60%)
    {'name': 'Red', 'color': Color(0xFFEB5757)}, // HSL(0, 84%, 60%)
    {'name': 'Green', 'color': Color(0xFF22C55E)}, // HSL(142, 71%, 45%)
    {'name': 'Purple', 'color': Color(0xFFA855F7)}, // HSL(262, 83%, 58%)
    {'name': 'Black', 'color': Color(0xFF171717)}, // HSL(0, 0%, 9%)
  ];

  // Light theme colors
  static const Color lightBackground = Color(0xFFFAFAFA); // HSL(0, 0%, 98%)
  static const Color lightForeground = Color(0xFF2B2B2B); // HSL(220, 15%, 15%)
  static const Color lightCard = Color(0xFFFFFFFF); // HSL(0, 0%, 100%)
  static const Color lightMuted = Color(0xFFF5F5F5); // HSL(220, 10%, 96%)
  static const Color lightMutedForeground = Color(
    0xFF737373,
  ); // HSL(220, 10%, 45%)
  static const Color lightBorder = Color(0xFFE6E6E6); // HSL(220, 15%, 90%)

  // Dark theme colors
  static const Color darkBackground = Color(0xFF141414); // HSL(220, 25%, 8%)
  static const Color darkForeground = Color(0xFFF2F2F2); // HSL(220, 10%, 95%)
  static const Color darkCard = Color(0xFF1F1F1F); // HSL(220, 20%, 12%)
  static const Color darkMuted = Color(0xFF2E2E2E); // HSL(220, 20%, 18%)
  static const Color darkMutedForeground = Color(
    0xFF999999,
  ); // HSL(220, 10%, 60%)
  static const Color darkBorder = Color(0xFF333333); // HSL(220, 20%, 20%)

  // Sidebar colors
  static const Color lightSidebarBackground = Color(0xFFFAFAFA);
  static const Color lightSidebarForeground = Color(0xFF424242);
  static const Color lightSidebarBorder = Color(0xFFE8E8E8);

  static const Color darkSidebarBackground = Color(0xFF1A1A1A);
  static const Color darkSidebarForeground = Color(0xFFF5F5F5);
  static const Color darkSidebarBorder = Color(0xFF282828);

  // Light theme matching CSS design system
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: lightCard,
      surfaceContainerHighest: lightMuted,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightForeground,
      onSurfaceVariant: lightMutedForeground,
      outline: lightBorder,
    ),
    scaffoldBackgroundColor: lightBackground,
    cardTheme: CardThemeData(
      elevation: 2, // Subtle elevation for mockup
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)), // Updated from 8
        side: BorderSide(color: lightBorder, width: 1),
      ),
      color: lightCard,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: lightBackground,
      foregroundColor: lightForeground,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondaryColor.withValues(alpha: 0.1),
      labelStyle: const TextStyle(color: lightForeground),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    dividerColor: lightBorder,
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: lightMuted,
    ),
  );

  // Dark theme matching CSS design system
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: darkCard,
      surfaceContainerHighest: darkMuted,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkForeground,
      onSurfaceVariant: darkMutedForeground,
      outline: darkBorder,
    ),
    scaffoldBackgroundColor: darkBackground,
    cardTheme: CardThemeData(
      elevation: 2, // Subtle elevation for mockup
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)), // Updated from 8
        side: BorderSide(color: darkBorder, width: 1),
      ),
      color: darkCard,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: darkBackground,
      foregroundColor: darkForeground,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: secondaryColor.withValues(alpha: 0.2),
      labelStyle: const TextStyle(color: darkForeground),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
    dividerColor: darkBorder,
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryColor,
      linearTrackColor: darkMuted,
    ),
  );
}

// Extension for custom colors
extension CustomColors on ColorScheme {
  Color get success => AppTheme.successColor;
  Color get warning => AppTheme.warningColor;
}

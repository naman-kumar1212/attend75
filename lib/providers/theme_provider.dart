import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../utils/page_transitions.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppTheme.primaryColor;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      final themeModeString = prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = _parseThemeMode(themeModeString);
      }

      // Load accent color
      final accentColorValue = prefs.getInt(_accentColorKey);
      if (accentColorValue != null) {
        _accentColor = Color(accentColorValue);
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(mode));
    } catch (e) {
      debugPrint('Failed to save theme mode: $e');
    }
  }

  void toggleTheme() {
    // Toggle between light and dark (ignore system for toggle)
    if (_themeMode == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  Future<void> setAccentColor(Color color) async {
    debugPrint('Setting accent color to: ${color.toARGB32()}');

    _accentColor = color;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = color.toARGB32();
      await prefs.setInt(_accentColorKey, colorValue);
      debugPrint('Accent color saved: $colorValue');
    } catch (e) {
      debugPrint('Failed to save accent color: $e');
    }
  }

  // Get theme data with custom accent color
  ThemeData getLightTheme() {
    return AppTheme.lightTheme.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.robotoTextTheme(AppTheme.lightTheme.textTheme),
      primaryTextTheme: GoogleFonts.robotoTextTheme(
        AppTheme.lightTheme.primaryTextTheme,
      ),
      colorScheme: AppTheme.lightTheme.colorScheme.copyWith(
        primary: _accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _accentColor,
        linearTrackColor: AppTheme.lightMuted,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: _accentColor),
        selectedLabelTextStyle: TextStyle(
          color: _accentColor,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: _accentColor.withValues(alpha: 0.12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _accentColor.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _accentColor);
          }
          return const IconThemeData(color: AppTheme.lightMutedForeground);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppTheme.lightMutedForeground,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeData getDarkTheme() {
    return AppTheme.darkTheme.copyWith(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: GoogleFonts.robotoTextTheme(AppTheme.darkTheme.textTheme),
      primaryTextTheme: GoogleFonts.robotoTextTheme(
        AppTheme.darkTheme.primaryTextTheme,
      ),
      colorScheme: AppTheme.darkTheme.colorScheme.copyWith(
        primary: _accentColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _accentColor,
        linearTrackColor: AppTheme.darkMuted,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedIconTheme: IconThemeData(color: _accentColor),
        selectedLabelTextStyle: TextStyle(
          color: _accentColor,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: _accentColor.withValues(alpha: 0.12),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _accentColor.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _accentColor);
          }
          return const IconThemeData(color: AppTheme.darkMutedForeground);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: _accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppTheme.darkMutedForeground,
            fontSize: 12,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.darkMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.errorColor),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

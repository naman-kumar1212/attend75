import 'package:flutter/material.dart';

/// Snackbar utility similar to React's toast system
class SnackbarHelper {
  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 5);

  /// Show a success snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
      action: action,
    );
  }

  /// Show an error snackbar
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration ?? _longDuration,
      action: action,
    );
  }

  /// Show a warning snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
      action: action,
    );
  }

  /// Show an info snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
      action: action,
    );
  }

  /// Show a default snackbar
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
    IconData? icon,
  }) {
    _showSnackbar(
      context,
      message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      action: action,
    );
  }

  /// Show a snackbar using pre-captured ScaffoldMessengerState (for async safety)
  static void showWithMessenger(
    ScaffoldMessengerState messenger,
    String message, {
    Duration? duration,
    SnackBarAction? action,
    Color? backgroundColor,
    IconData? icon,
  }) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: (backgroundColor ?? const Color(0xFF323232))
            .withValues(alpha: 0.95),
        duration: duration ?? _defaultDuration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  static void _showSnackbar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars(); // Avoid stacking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: (backgroundColor ?? const Color(0xFF323232))
            .withValues(alpha: 0.95),
        duration: duration ?? _defaultDuration,
        action: action,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/settings_service.dart';

/// Attendance settings matching useAttendanceSettings.ts
class AttendanceSettings {
  final double defaultRequiredAttendance;
  final bool includeDutyLeaves;
  final double showWarningAt;
  final double showCriticalAt;
  final bool autoMarkWeekends;
  final bool notificationsEnabled;
  final String reminderTime; // HH:MM format

  const AttendanceSettings({
    this.defaultRequiredAttendance = 75.0,
    this.includeDutyLeaves = true,
    this.showWarningAt = 80.0,
    this.showCriticalAt = 75.0,
    this.autoMarkWeekends = false,
    this.notificationsEnabled = true,
    this.reminderTime = "09:00",
  });

  Map<String, dynamic> toJson() => {
    'defaultRequiredAttendance': defaultRequiredAttendance,
    'includeDutyLeaves': includeDutyLeaves,
    'showWarningAt': showWarningAt,
    'showCriticalAt': showCriticalAt,
    'autoMarkWeekends': autoMarkWeekends,
    'notificationsEnabled': notificationsEnabled,
    'reminderTime': reminderTime,
  };

  factory AttendanceSettings.fromJson(Map<String, dynamic> json) {
    return AttendanceSettings(
      defaultRequiredAttendance:
          (json['defaultRequiredAttendance'] as num?)?.toDouble() ?? 75.0,
      includeDutyLeaves: json['includeDutyLeaves'] as bool? ?? true,
      showWarningAt: (json['showWarningAt'] as num?)?.toDouble() ?? 80.0,
      showCriticalAt: (json['showCriticalAt'] as num?)?.toDouble() ?? 75.0,
      autoMarkWeekends: json['autoMarkWeekends'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderTime: json['reminderTime'] as String? ?? "09:00",
    );
  }

  /// Create settings from Supabase database row.
  factory AttendanceSettings.fromSupabase(Map<String, dynamic> json) {
    return AttendanceSettings(
      defaultRequiredAttendance:
          (json['default_required_attendance'] as num?)?.toDouble() ?? 75.0,
      includeDutyLeaves: json['include_duty_leave'] as bool? ?? true,
      showWarningAt: (json['show_warning_at'] as num?)?.toDouble() ?? 80.0,
      showCriticalAt: (json['show_critical_at'] as num?)?.toDouble() ?? 75.0,
      autoMarkWeekends: json['auto_mark_weekends'] as bool? ?? false,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      reminderTime: json['reminder_time'] as String? ?? "09:00",
    );
  }

  /// Convert to Supabase database format.
  Map<String, dynamic> toSupabase() => {
    'default_required_attendance': defaultRequiredAttendance,
    'include_duty_leave': includeDutyLeaves,
    'show_warning_at': showWarningAt,
    'show_critical_at': showCriticalAt,
    'auto_mark_weekends': autoMarkWeekends,
    'notifications_enabled': notificationsEnabled,
    'reminder_time': reminderTime,
  };

  AttendanceSettings copyWith({
    double? defaultRequiredAttendance,
    bool? includeDutyLeaves,
    double? showWarningAt,
    double? showCriticalAt,
    bool? autoMarkWeekends,
    bool? notificationsEnabled,
    String? reminderTime,
  }) {
    return AttendanceSettings(
      defaultRequiredAttendance:
          defaultRequiredAttendance ?? this.defaultRequiredAttendance,
      includeDutyLeaves: includeDutyLeaves ?? this.includeDutyLeaves,
      showWarningAt: showWarningAt ?? this.showWarningAt,
      showCriticalAt: showCriticalAt ?? this.showCriticalAt,
      autoMarkWeekends: autoMarkWeekends ?? this.autoMarkWeekends,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

enum SaveStatus { idle, saving, saved, error }

/// Settings provider with Supabase cloud sync.
class SettingsProvider extends ChangeNotifier {
  static const String _settingsKey = 'attendanceSettings';

  final SettingsService _settingsService = SettingsService();

  AttendanceSettings _settings = const AttendanceSettings();
  SaveStatus _saveStatus = SaveStatus.idle;
  bool _isLoading = true;
  bool _isSyncing = false;

  AttendanceSettings get settings => _settings;
  SaveStatus get saveStatus => _saveStatus;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load from local cache first
    await _loadFromLocalCache();

    // Then sync with Supabase if authenticated
    if (SupabaseService.isAuthenticated) {
      await syncWithSupabase();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load settings from local SharedPreferences cache.
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        _settings = AttendanceSettings.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Failed to load settings from cache: $e');
    }
  }

  /// Save settings to local cache.
  Future<void> _saveToLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_settings.toJson());
      await prefs.setString(_settingsKey, encoded);
    } catch (e) {
      debugPrint('Failed to save settings to cache: $e');
    }
  }

  /// Sync settings with Supabase.
  Future<void> syncWithSupabase() async {
    if (!SupabaseService.isAuthenticated) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final cloudSettings = await _settingsService.getSettings();
      if (cloudSettings != null) {
        _settings = AttendanceSettings.fromSupabase(cloudSettings);
        await _saveToLocalCache();
      }
    } catch (e) {
      debugPrint('Error syncing settings with Supabase: $e');
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Called when user logs in.
  Future<void> onUserLogin() async {
    await syncWithSupabase();
  }

  /// Called when user logs out.
  Future<void> onUserLogout() async {
    // Keep local settings but don't sync
    _settings = const AttendanceSettings();
    await _saveToLocalCache();
    notifyListeners();
  }

  /// Update settings and sync to cloud.
  Future<void> updateSettings(AttendanceSettings newSettings) async {
    // Validate settings
    _validateSettings(newSettings);

    _saveStatus = SaveStatus.saving;
    _settings = newSettings;
    notifyListeners();

    try {
      // Save to local cache
      await _saveToLocalCache();

      // Sync to Supabase
      if (SupabaseService.isAuthenticated) {
        await _settingsService.updateSettings(newSettings.toSupabase());
      }

      _saveStatus = SaveStatus.saved;
      notifyListeners();

      // Reset status after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to save settings: $e');
      _saveStatus = SaveStatus.error;
      notifyListeners();

      // Reset status after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      _saveStatus = SaveStatus.idle;
      notifyListeners();
    }
  }

  void _validateSettings(AttendanceSettings settings) {
    if (settings.defaultRequiredAttendance < 50 ||
        settings.defaultRequiredAttendance > 100) {
      throw ArgumentError(
        'Default required attendance must be between 50% and 100%',
      );
    }

    if (settings.showWarningAt < 50 || settings.showWarningAt > 100) {
      throw ArgumentError('Warning threshold must be between 50% and 100%');
    }

    if (settings.showCriticalAt < 50 || settings.showCriticalAt > 100) {
      throw ArgumentError('Critical threshold must be between 50% and 100%');
    }

    if (settings.showCriticalAt > settings.showWarningAt) {
      throw ArgumentError(
        'Critical threshold must be less than or equal to warning threshold',
      );
    }

    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(settings.reminderTime)) {
      throw ArgumentError('Invalid reminder time format. Expected HH:MM');
    }
  }

  Future<void> resetSettings() async {
    await updateSettings(const AttendanceSettings());
  }
}

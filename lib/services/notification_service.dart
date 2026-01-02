import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for showing native Android/iOS push notifications.
/// Used for important events like auth, attendance warnings, etc.
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Notification channel IDs for Android
  static const String _authChannelId = 'auth_channel';
  static const String _attendanceChannelId = 'attendance_channel';
  static const String _reminderChannelId = 'reminder_channel';

  // Notification IDs (unique per notification type)
  static const int _signUpNotificationId = 1;
  static const int _signInNotificationId = 2;
  static const int _subjectAddedNotificationId = 3;
  static const int _lowAttendanceNotificationId = 4;
  static const int _dutyLeaveNotificationId = 5;
  static const int _reminderNotificationId = 100;

  /// Initialize the notification service.
  /// Call this in main() after Supabase initialization.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // We handle this separately
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Auth channel (sign up, sign in)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _authChannelId,
        'Authentication',
        description: 'Notifications for sign in and sign up events',
        importance: Importance.high,
      ),
    );

    // Attendance channel (warnings, duty leave)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _attendanceChannelId,
        'Attendance',
        description: 'Notifications for attendance updates and warnings',
        importance: Importance.high,
      ),
    );

    // Reminder channel (daily reminders)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannelId,
        'Reminders',
        description: 'Daily attendance reminders',
        importance: Importance.defaultImportance,
      ),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to specific page based on payload if needed
    // if (response.payload == 'duty_leave') ...
  }

  // ============================================
  // AUTH NOTIFICATIONS
  // ============================================

  /// Show notification for successful sign up
  Future<void> showSignUpSuccess(String userName) async {
    await _showNotification(
      id: _signUpNotificationId,
      channelId: _authChannelId,
      title: 'Welcome to Attend75! 🎉',
      body: 'Hi $userName, your account has been created successfully.',
      payload: 'signup',
    );
  }

  /// Show notification for successful sign in
  Future<void> showSignInSuccess(String userName) async {
    await _showNotification(
      id: _signInNotificationId,
      channelId: _authChannelId,
      title: 'Welcome back! 👋',
      body: 'Signed in as $userName',
      payload: 'signin',
    );
  }

  // ============================================
  // SUBJECT NOTIFICATIONS
  // ============================================

  /// Show notification when a new subject is added
  Future<void> showSubjectAdded(String subjectName) async {
    await _showNotification(
      id: _subjectAddedNotificationId,
      channelId: _attendanceChannelId,
      title: 'New Subject Added 📚',
      body: '$subjectName has been added to your subjects.',
      payload: 'subject_added',
    );
  }

  // ============================================
  // ATTENDANCE NOTIFICATIONS
  // ============================================

  /// Show low attendance warning notification
  Future<void> showLowAttendanceWarning({
    required String subjectName,
    required double percentage,
    required double requiredPercentage,
  }) async {
    await _showNotification(
      id: _lowAttendanceNotificationId,
      channelId: _attendanceChannelId,
      title: '⚠️ Low Attendance Warning',
      body:
          '$subjectName is at ${percentage.toStringAsFixed(1)}% (required: ${requiredPercentage.toStringAsFixed(0)}%)',
      payload: 'low_attendance',
    );
  }

  /// Show notification when duty leave is applied successfully
  Future<void> showDutyLeaveApplied({
    required String subjectName,
    required String date,
  }) async {
    await _showNotification(
      id: _dutyLeaveNotificationId,
      channelId: _attendanceChannelId,
      title: 'Duty Leave Applied ✓',
      body: 'Duty leave for $subjectName on $date has been approved.',
      payload: 'duty_leave',
    );
  }

  // ============================================
  // REMINDER NOTIFICATIONS
  // ============================================

  /// Show daily attendance reminder
  Future<void> showDailyReminder({required int classCount}) async {
    if (classCount == 0) return;

    await _showNotification(
      id: _reminderNotificationId,
      channelId: _reminderChannelId,
      title: 'Attendance Reminder 📝',
      body:
          'You have $classCount class${classCount > 1 ? 'es' : ''} today. Don\'t forget to mark attendance!',
      payload: 'reminder',
    );
  }

  // ============================================
  // CORE NOTIFICATION METHOD
  // ============================================

  Future<void> _showNotification({
    required int id,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('NotificationService not initialized');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _authChannelId
          ? 'Authentication'
          : channelId == _attendanceChannelId
          ? 'Attendance'
          : 'Reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(id, title, body, details, payload: payload);
      debugPrint('Notification shown: $title');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

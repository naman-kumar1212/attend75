import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Minimal centralized permission handling service
/// - No in-app dialogs
/// - System permission dialogs only
/// - Silent failure handling
class PermissionsService {
  // Singleton
  static final PermissionsService _instance = PermissionsService._internal();
  factory PermissionsService() => _instance;
  PermissionsService._internal();

  // ============================================
  // NOTIFICATION PERMISSION
  // ============================================

  /// Request notification permission (system dialog only)
  /// Call on app launch for Android 13+
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Check notification status without requesting
  Future<bool> isNotificationGranted() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // ============================================
  // PHOTO / GALLERY PERMISSION
  // ============================================

  /// Request photo permission (system dialog only)
  Future<bool> requestPhotoPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    Permission permission = Permission.photos;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 33) {
        permission = Permission.storage;
      }
    }

    final status = await permission.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await permission.request();
    return result.isGranted;
  }

  // ============================================
  // FILE / STORAGE PERMISSION
  // ============================================

  /// Request file/storage permission (system dialog only)
  /// Note: Android 10+ scoped storage doesn't require permission for file picker
  Future<bool> requestFilePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    // Android 10+ (API 29+) uses scoped storage - no permission needed for file picker
    if (androidInfo.version.sdkInt >= 29) return true;

    final status = await Permission.storage.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.storage.request();
    return result.isGranted;
  }

  // ============================================
  // CAMERA PERMISSION
  // ============================================

  /// Request camera permission (system dialog only)
  Future<bool> requestCameraPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.camera.request();
    return result.isGranted;
  }
}

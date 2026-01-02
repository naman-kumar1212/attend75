import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';

/// Authentication provider using Supabase Auth.
/// Manages user authentication state and profile data.
///
/// CRITICAL: Profile data is ALWAYS populated for authenticated users.
/// The UI should NEVER see null values for firstName, lastName, or email.
///
/// SECURITY: Password recovery sessions are tracked separately.
/// Users in recovery mode are NOT treated as authenticated.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  StreamSubscription<AuthState>? _authSubscription;

  /// SharedPreferences key for persistent recovery state
  static const String _recoveryInProgressKey = 'password_recovery_in_progress';
  static const String _guestModeKey = 'guest_mode_active';

  bool _isSignedIn = false;
  bool _isInRecoveryMode = false;
  bool _isGuestMode = false;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isProfileLoading = false;
  bool _isProfileReady = false;
  String? _errorMessage;
  bool _emailConfirmationRequired = false;
  String? _pendingConfirmationEmail;

  /// Returns true only if user is authenticated AND not in recovery mode.
  /// Users in password recovery flow are NOT considered signed in.
  /// Guest users are also considered "signed in" for navigation purposes.
  bool get isSignedIn => (_isSignedIn && !_isInRecoveryMode) || _isGuestMode;

  /// Returns true if user is in guest mode (not logged in but using app).
  bool get isGuest => _isGuestMode;

  /// Returns true if we're in password recovery mode.
  bool get isInRecoveryMode => _isInRecoveryMode;

  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  bool get isProfileReady => _isProfileReady && _profile != null;
  String? get errorMessage => _errorMessage;
  bool get emailConfirmationRequired => _emailConfirmationRequired;
  String? get pendingConfirmationEmail => _pendingConfirmationEmail;

  // Convenience getters with SAFE FALLBACKS
  // These NEVER return null - they return empty string if no data
  String get firstName {
    // Priority: profile > user metadata > empty
    return _profile?['first_name']?.toString() ??
        _user?['firstName']?.toString() ??
        '';
  }

  String get lastName {
    return _profile?['last_name']?.toString() ??
        _user?['lastName']?.toString() ??
        '';
  }

  String get fullName {
    final first = firstName;
    final last = lastName;
    if (first.isEmpty && last.isEmpty) return '';
    return '$first $last'.trim();
  }

  String get email {
    return _profile?['email']?.toString() ??
        _user?['email']?.toString() ??
        _authService.currentUser?.email ??
        '';
  }

  String? get avatarUrl => _profile?['avatar_url']?.toString();

  double get targetAttendance =>
      (_profile?['target_attendance'] as num?)?.toDouble() ?? 75.0;

  /// Get initials for avatar fallback - NEVER returns empty
  String get initials {
    final first = firstName;
    final last = lastName;

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    } else if (first.isNotEmpty) {
      return first[0].toUpperCase();
    } else if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // SECURITY: Check for stale password recovery state FIRST
    // If recovery was in progress but password wasn't updated, force sign out
    final wasInRecovery = await _checkRecoveryInProgress();

    if (wasInRecovery && _authService.isLoggedIn) {
      debugPrint(
        'AuthProvider: Stale recovery session detected, forcing sign out',
      );
      await _authService.signOut();
      await _clearRecoveryMode();
      _isSignedIn = false;
      _isInRecoveryMode = false;
      _user = null;
      _profile = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Check for guest mode
    _isGuestMode = await _checkGuestMode();

    // Check for existing session
    _isSignedIn = _authService.isLoggedIn;

    if (_isSignedIn) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();

    // Listen to auth state changes
    _authSubscription = _authService.authStateChanges.listen((state) async {
      final event = state.event;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Skip if in recovery mode - don't treat as normal sign in
        if (_isInRecoveryMode) {
          debugPrint('AuthProvider: Ignoring signedIn during recovery mode');
          return;
        }
        // Clear guest mode when user signs in (e.g., via OAuth)
        await _clearGuestMode();
        _isSignedIn = true;
        await _loadUserData();
      } else if (event == AuthChangeEvent.signedOut) {
        _isSignedIn = false;
        _isInRecoveryMode = false;
        _user = null;
        _profile = null;
      }

      notifyListeners();
    });
  }

  /// Set recovery mode - called when passwordRecovery event is received.
  /// Persists to SharedPreferences to survive app restarts.
  Future<void> setRecoveryMode(bool inRecovery) async {
    _isInRecoveryMode = inRecovery;
    final prefs = await SharedPreferences.getInstance();
    if (inRecovery) {
      await prefs.setBool(_recoveryInProgressKey, true);
      debugPrint('AuthProvider: Recovery mode SET');
    } else {
      await prefs.remove(_recoveryInProgressKey);
      debugPrint('AuthProvider: Recovery mode CLEARED');
    }
    notifyListeners();
  }

  /// Check if password recovery is in progress (reads from SharedPreferences).
  Future<bool> _checkRecoveryInProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_recoveryInProgressKey) ?? false;
  }

  /// Clear recovery mode after successful password update.
  Future<void> _clearRecoveryMode() async {
    _isInRecoveryMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryInProgressKey);
    debugPrint('AuthProvider: Recovery mode CLEARED');
  }

  /// Continue using the app as a guest (without logging in).
  /// Guest data is stored locally only and will be cleared on login.
  Future<void> continueAsGuest() async {
    _isGuestMode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, true);
    debugPrint('AuthProvider: Guest mode ENABLED');
    notifyListeners();
  }

  /// Check if guest mode is active (reads from SharedPreferences).
  Future<bool> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  /// Clear guest mode when user logs in.
  Future<void> _clearGuestMode() async {
    _isGuestMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestModeKey);
    debugPrint('AuthProvider: Guest mode CLEARED');
  }

  /// Ensure profile is loaded - awaitable by UI components.
  /// Call this before accessing profile data in UI.
  Future<void> ensureProfileLoaded() async {
    if (_isProfileReady && _profile != null) return;
    await _loadUserData();
  }

  /// Load user data from auth and profile table.
  /// GUARANTEES: _user and _profile are populated after this completes.
  /// Uses retry logic for transient database failures.
  Future<void> _loadUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    _isProfileLoading = true;
    _isProfileReady = false;
    notifyListeners();

    // Step 1: Populate _user from auth metadata (immediate, always available)
    final userMeta = currentUser.userMetadata;
    debugPrint('AuthProvider: Metadata keys: ${userMeta?.keys.toList()}');

    // Extract name - handle both separate fields and full name
    String firstName = userMeta?['first_name']?.toString() ?? '';
    String lastName = userMeta?['last_name']?.toString() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      final fullName = userMeta?['full_name'] ?? userMeta?['name'] ?? '';
      if (fullName != null && fullName.toString().isNotEmpty) {
        final parts = fullName.toString().split(' ');
        if (parts.isNotEmpty) {
          firstName = parts.first;
          if (parts.length > 1) {
            lastName = parts.sublist(1).join(' ');
          }
        }
      }
    }

    _user = {
      'id': currentUser.id,
      'email': currentUser.email ?? '',
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl':
          userMeta?['avatar_url']?.toString() ??
          userMeta?['picture']?.toString(),
    };

    // Also populate _profile immediately with what we have
    // This allows UI to show avatar/name while we fetch/create the full DB profile
    _profile ??= {
      'id': currentUser.id,
      'email': currentUser.email ?? '',
      'first_name': _user!['firstName'],
      'last_name': _user!['lastName'],
      'avatar_url': _user!['avatarUrl'],
      'target_attendance': 75.0,
    };

    // Step 2: Load or create profile from database with retry
    // Retry up to 3 times with exponential backoff for new signups
    // (database trigger may not have completed yet)
    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      _profile = await _profileService.getOrCreateProfile();

      if (_profile != null) {
        debugPrint('Profile loaded on attempt ${attempt + 1}');
        break;
      }

      // Exponential backoff: 200ms, 400ms, 800ms
      if (attempt < maxRetries - 1) {
        final delayMs = 200 * (1 << attempt);
        debugPrint(
          'Profile null, retrying in ${delayMs}ms (attempt ${attempt + 1}/$maxRetries)',
        );
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    // Step 3: If profile somehow still null after retries, create from auth data
    if (_profile == null) {
      debugPrint(
        'CRITICAL: Profile still null after $maxRetries retries, using auth fallback',
      );
      _profile = {
        'id': currentUser.id,
        'email': currentUser.email ?? '',
        'first_name': currentUser.userMetadata?['first_name']?.toString() ?? '',
        'last_name': currentUser.userMetadata?['last_name']?.toString() ?? '',
        'target_attendance': 75.0,
      };
    }

    _isProfileLoading = false;
    _isProfileReady = true;
    notifyListeners();

    debugPrint(
      'Profile loaded: firstName=$firstName, lastName=$lastName, email=$email',
    );
  }

  /// Sign in with email and password.
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signIn(email, password);

      if (response.user != null) {
        // Clear guest mode when user logs in
        await _clearGuestMode();

        _isSignedIn = true;
        await _loadUserData();
        _isLoading = false;
        notifyListeners();

        // Show native notification
        NotificationService().showSignInSuccess(
          firstName.isNotEmpty ? firstName : email,
        );

        return true;
      }

      _errorMessage = 'Sign in failed. Please check your credentials.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      // Check for email not confirmed error
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('email not confirmed') ||
          errorMessage.contains('email_not_confirmed')) {
        _errorMessage =
            'Please verify your email before signing in. Check your inbox for the confirmation link.';
        _emailConfirmationRequired = true;
        _pendingConfirmationEmail = email;
      } else {
        _errorMessage = _parseAuthError(e.message);
      }
      _isSignedIn = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('email not confirmed') ||
          errorString.contains('email_not_confirmed')) {
        _errorMessage =
            'Please verify your email before signing in. Check your inbox for the confirmation link.';
        _emailConfirmationRequired = true;
        _pendingConfirmationEmail = email;
      } else {
        _errorMessage = _parseAuthError(e.toString());
      }
      _isSignedIn = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password.
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if we have a session (email confirmation disabled)
        // or just a user (email confirmation enabled - no session yet)
        final hasSession = response.session != null;

        if (hasSession) {
          // Email confirmation disabled - user is fully signed in
          _isSignedIn = true;

          // IMMEDIATELY store user data from signup params
          _user = {
            'id': response.user!.id,
            'email': email,
            'firstName': firstName,
            'lastName': lastName,
          };

          // Also create a fallback profile object immediately
          _profile = {
            'id': response.user!.id,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'target_attendance': 75.0,
          };

          debugPrint(
            'AuthProvider.signUp: Stored immediate user data - $firstName $lastName',
          );

          // Now try to load/create profile from database
          try {
            await _loadUserData();
          } catch (e) {
            debugPrint(
              'AuthProvider.signUp: _loadUserData failed, using fallback - $e',
            );
            _isProfileReady = true;
          }

          _isLoading = false;
          notifyListeners();

          // Show native notification
          NotificationService().showSignUpSuccess(firstName);

          return true;
        } else {
          // Email confirmation enabled - user created but needs to verify email
          debugPrint(
            'AuthProvider.signUp: Email confirmation required for $email',
          );
          _isSignedIn = false;
          _user = null;
          _profile = null;
          _emailConfirmationRequired = true;
          _pendingConfirmationEmail = email;
          _isLoading = false;
          notifyListeners();

          // Return true to indicate signup was successful (user should check email)
          return true;
        }
      }

      _errorMessage = 'Sign up failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      // Check if this is a confirmation email error - signup succeeded but email failed
      final errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('confirmation email') ||
          errorMessage.contains('sending confirmation') ||
          errorMessage.contains('unexpected_failure')) {
        // The signup succeeded, but email sending failed
        // Return false with clear error message
        debugPrint('AuthProvider.signUp: Email confirmation failed - $email');
        _errorMessage = 'Could not send confirmation email. Please try again.';
        _isSignedIn = false;
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Parse the error and provide user-friendly messages
      _errorMessage = _parseAuthError(e.message);
      _isSignedIn = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Check if this is a confirmation email error - signup may have succeeded
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('confirmation email') ||
          errorString.contains('sending confirmation')) {
        // The signup likely succeeded, but email sending failed
        debugPrint(
          'AuthProvider.signUp: Email confirmation failed - may need retry',
        );
        _errorMessage = 'Could not send confirmation email. Please try again.';
        _isSignedIn = false;
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _errorMessage = _parseAuthError(e.toString());
      _isSignedIn = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Parse error messages to provide user-friendly text.
  /// Converts raw Supabase/JSON errors into readable messages.
  String _parseAuthError(String error) {
    final lowerError = error.toLowerCase();

    // Check for common error patterns
    if (lowerError.contains('email already') ||
        lowerError.contains('user already registered')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (lowerError.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (lowerError.contains('password') && lowerError.contains('weak')) {
      return 'Password is too weak. Use at least 8 characters with uppercase, lowercase, and numbers.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lowerError.contains('rate limit') || lowerError.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lowerError.contains('signups are disabled')) {
      return 'Signups are currently disabled. Please try again later.';
    }

    // If it looks like raw JSON, provide a generic message
    if (error.contains('{') && error.contains('}')) {
      return 'Something went wrong. Please try again.';
    }

    // Return original if it seems user-friendly already
    if (error.length < 100 && !error.contains('{')) {
      return error;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Update user profile data.
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _profileService.updateProfile(data);

      if (success) {
        // Refresh profile data
        _profile = await _profileService.getOrCreateProfile();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user's avatar.
  Future<String?> updateAvatar(dynamic imageFile) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? url;

      if (imageFile is String) {
        // It's a file path - not supported in this flow
        debugPrint('File path not supported, use File object');
      } else {
        url = await _profileService.uploadAvatar(imageFile);
      }

      if (url != null) {
        _profile = await _profileService.getOrCreateProfile();
      }

      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      debugPrint('Update Avatar Error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
    _isSignedIn = false;
    _user = null;
    _profile = null;
    notifyListeners();
  }

  /// Refresh user data from the server.
  Future<void> refreshUserData() async {
    if (_isSignedIn) {
      await _loadUserData();
      notifyListeners();
    }
  }

  /// Sign in with Google OAuth.
  /// This handles both sign-in and sign-up - new users are automatically created.
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithGoogle();

      if (success) {
        // The OAuth flow will redirect the user to Google's sign-in page.
        // After successful authentication, the auth state listener will
        // handle the signed-in state and load user data.
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Google sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Apple OAuth.
  /// This handles both sign-in and sign-up - new users are automatically created.
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.signInWithApple();

      if (success) {
        // The OAuth flow will redirect the user to Apple's sign-in page.
        // After successful authentication, the auth state listener will
        // handle the signed-in state and load user data.
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Apple sign in failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend confirmation email to an unconfirmed user.
  /// Returns true if email was sent successfully.
  Future<bool> resendConfirmationEmail() async {
    if (_pendingConfirmationEmail == null) {
      _errorMessage = 'No pending email confirmation found.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.resendConfirmationEmail(_pendingConfirmationEmail!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email to a user.
  /// Returns true if email was sent successfully, false if email doesn't exist or error occurred.
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // First check if the email exists
      final emailExists = await _authService.checkEmailExists(email);

      if (!emailExists) {
        _errorMessage = 'No account found with this email address.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Email exists, send reset email
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update the user's password (used after password reset deep link).
  /// Returns true if password was updated successfully.
  /// SECURITY: Clears recovery mode flag on success.
  Future<bool> updateUserPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.updatePassword(newPassword);

      // SECURITY: Clear recovery mode on successful password update
      await _clearRecoveryMode();

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseAuthError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message and email confirmation state.
  void clearError() {
    _errorMessage = null;
    _emailConfirmationRequired = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

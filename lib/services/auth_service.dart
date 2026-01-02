import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service using Supabase Auth.
/// Handles sign up, sign in, sign out, and session management.
class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  /// Redirect URL for email verification deep link
  static const String emailRedirectUrl =
      'com.example.attend75://login-callback';

  /// Sign up a new user with email and password.
  /// First name and last name are stored in user metadata.
  /// With email confirmation enabled, no session is returned immediately.
  Future<AuthResponse> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
        emailRedirectTo: emailRedirectUrl, // Deep link for email verification
      );
      return response;
    } catch (e) {
      debugPrint('Sign Up Error: $e');
      rethrow;
    }
  }

  /// Sign in an existing user with email and password.
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      debugPrint('Sign In Error: $e');
      rethrow;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      rethrow;
    }
  }

  /// Get the currently authenticated user.
  User? get currentUser => _client.auth.currentUser;

  /// Check if a user is logged in.
  bool get isLoggedIn => currentUser != null;

  /// Stream of authentication state changes.
  /// Use this to reactively update UI when auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Get the current session.
  Session? get currentSession => _client.auth.currentSession;

  /// Refresh the current session.
  Future<AuthResponse> refreshSession() async {
    return await _client.auth.refreshSession();
  }

  /// Send a password reset email with deep link redirect.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: emailRedirectUrl,
    );
  }

  /// Check if an email is registered in the system.
  /// Returns true if the email exists, false otherwise.
  Future<bool> checkEmailExists(String email) async {
    try {
      // Attempt to sign in with a dummy password
      // Supabase returns different errors for non-existent email vs wrong password
      await _client.auth.signInWithPassword(
        email: email,
        password: '_dummy_password_check_',
      );
      // If we get here, the password happened to be correct (extremely unlikely)
      await _client.auth.signOut();
      return true;
    } on AuthException catch (e) {
      final errorMessage = e.message.toLowerCase();
      // "Invalid login credentials" means the email exists but password is wrong
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid_credentials')) {
        return true;
      }
      // "Email not confirmed" also means the email exists
      if (errorMessage.contains('email not confirmed')) {
        return true;
      }
      // Other errors like "User not found" mean the email doesn't exist
      return false;
    } catch (e) {
      debugPrint('Check email exists error: $e');
      return false;
    }
  }

  /// Resend confirmation email to an unconfirmed user.
  /// Uses Supabase's built-in resend feature with 'signup' type.
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailRedirectUrl,
      );
    } catch (e) {
      debugPrint('Resend Confirmation Error: $e');
      rethrow;
    }
  }

  /// Update the user's password.
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Update user metadata (first name, last name, etc.)
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    return await _client.auth.updateUser(UserAttributes(data: data));
  }

  /// Sign in with Google OAuth.
  /// This handles both sign-in and sign-up - new users are automatically created.
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
            emailRedirectUrl, // Explicitly set redirect URL to match AndroidManifest
      );
      return response;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple OAuth.
  /// This handles both sign-in and sign-up - new users are automatically created.
  Future<bool> signInWithApple() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: emailRedirectUrl,
      );
      return response;
    } catch (e) {
      debugPrint('Apple Sign In Error: $e');
      rethrow;
    }
  }
}

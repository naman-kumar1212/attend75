import 'package:supabase_flutter/supabase_flutter.dart';

/// Core Supabase service providing access to the Supabase client
/// and common authentication utilities.
class SupabaseService {
  // Private constructor for singleton pattern
  SupabaseService._();
  static final SupabaseService _instance = SupabaseService._();
  static SupabaseService get instance => _instance;

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Get the currently authenticated user
  static User? get currentUser => client.auth.currentUser;

  /// Get the current user's ID
  static String? get userId => currentUser?.id;

  /// Check if a user is currently authenticated WITH a valid session.
  /// With email confirmation enabled, user may exist but session is null until verified.
  static bool get isAuthenticated => currentSession != null;

  /// Stream of authentication state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  /// Get the current session
  static Session? get currentSession => client.auth.currentSession;

  /// Check if the current session is valid
  static bool get hasValidSession => currentSession != null;
}

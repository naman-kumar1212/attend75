import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing subjects in Supabase.
/// Handles CRUD operations for user subjects.
class SubjectsService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get all subjects for the current user.
  Future<List<Map<String, dynamic>>> getSubjects() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('subjects')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Subjects Error: $e');
      return [];
    }
  }

  /// Create a new subject.
  /// Returns the created subject data.
  Future<Map<String, dynamic>?> createSubject(Map<String, dynamic> data) async {
    // Get userId with detailed logging
    final userId = SupabaseService.userId;
    final session = SupabaseService.currentSession;
    final currentUser = SupabaseService.currentUser;

    debugPrint(
      'CreateSubject: userId=$userId, hasSession=${session != null}, hasCurrentUser=${currentUser != null}',
    );

    if (userId == null) {
      debugPrint('CreateSubject FAILED: userId is null');
      debugPrint('  - hasSession: ${session != null}');
      debugPrint('  - currentUser: $currentUser');

      // Try to refresh the session if we have one but userId is still null
      if (session != null) {
        debugPrint('CreateSubject: Attempting session refresh...');
        try {
          await _client.auth.refreshSession();
          final refreshedUserId = SupabaseService.userId;
          if (refreshedUserId != null) {
            debugPrint(
              'CreateSubject: Session refresh successful, userId=$refreshedUserId',
            );
            data['user_id'] = refreshedUserId;

            final response = await _client
                .from('subjects')
                .insert(data)
                .select()
                .single();
            return response;
          }
        } catch (refreshError) {
          debugPrint('CreateSubject: Session refresh failed: $refreshError');
        }
      }
      return null;
    }

    try {
      // Ensure user_id is set
      data['user_id'] = userId;
      debugPrint('CreateSubject: Inserting with user_id=$userId, data=$data');

      final response = await _client
          .from('subjects')
          .insert(data)
          .select()
          .single();

      debugPrint('CreateSubject SUCCESS: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('SUPABASE ERROR - Create Subject: $e');
      if (e is PostgrestException) {
        debugPrint(
          'Postgrest Error Details: ${e.message} code: ${e.code} details: ${e.details}',
        );
      }
      debugPrint('User ID: ${SupabaseService.userId}');
      debugPrint('Session valid: ${SupabaseService.hasValidSession}');
      debugPrint('Data attempted: $data');
      return null;
    }
  }

  /// Update an existing subject.
  Future<bool> updateSubject(String id, Map<String, dynamic> data) async {
    final userId = SupabaseService.userId;
    if (userId == null) {
      debugPrint('Update Subject Error: user not authenticated');
      return false;
    }

    try {
      // Include user_id to satisfy RLS 'with check' clause
      data['user_id'] = userId;
      await _client.from('subjects').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update Subject Error: $e');
      return false;
    }
  }

  /// Delete a subject.
  /// This will also cascade delete all related attendance logs.
  Future<bool> deleteSubject(String id) async {
    try {
      await _client.from('subjects').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete Subject Error: $e');
      return false;
    }
  }

  /// Get a single subject by ID.
  Future<Map<String, dynamic>?> getSubject(String id) async {
    try {
      final response = await _client
          .from('subjects')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Get Subject Error: $e');
      return null;
    }
  }

  /// Subscribe to real-time changes for subjects.
  RealtimeChannel subscribeToSubjects(
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    final userId = SupabaseService.userId;

    return _client
        .channel('subjects_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'subjects',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            // Refetch all subjects on any change
            final subjects = await getSubjects();
            onData(subjects);
          },
        )
        .subscribe();
  }
}

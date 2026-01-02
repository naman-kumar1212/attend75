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
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      // Ensure user_id is set
      data['user_id'] = userId;

      final response = await _client
          .from('subjects')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('SUPABASE ERROR - Create Subject: $e');
      debugPrint('User ID: ${SupabaseService.userId}');
      debugPrint('Data attempted: $data');
      return null;
    }
  }

  /// Update an existing subject.
  Future<bool> updateSubject(String id, Map<String, dynamic> data) async {
    try {
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

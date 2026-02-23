import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing lecture slots in Supabase.
/// Handles CRUD operations for recurring lecture slots within a subject.
class LectureSlotsService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get all lecture slots for the current user.
  Future<List<Map<String, dynamic>>> getLectureSlots() async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('lecture_slots')
          .select()
          .eq('user_id', userId)
          .order('day_of_week')
          .order('start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Lecture Slots Error: $e');
      return [];
    }
  }

  /// Get lecture slots for a specific subject.
  Future<List<Map<String, dynamic>>> getLectureSlotsForSubject(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('lecture_slots')
          .select()
          .eq('subject_id', subjectId)
          .order('day_of_week')
          .order('start_time');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Lecture Slots for Subject Error: $e');
      return [];
    }
  }

  /// Create a new lecture slot.
  /// Returns the created lecture slot data.
  Future<Map<String, dynamic>?> createLectureSlot(
    Map<String, dynamic> data,
  ) async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      // Ensure user_id is set
      data['user_id'] = userId;

      final response = await _client
          .from('lecture_slots')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('SUPABASE ERROR - Create Lecture Slot: $e');
      debugPrint('Data attempted: $data');
      return null;
    }
  }

  /// Create multiple lecture slots at once.
  /// Useful when adding a subject with multiple slots.
  Future<List<Map<String, dynamic>>> createLectureSlots(
    List<Map<String, dynamic>> slots,
  ) async {
    final userId = SupabaseService.userId;
    if (userId == null) return [];

    try {
      // Ensure user_id is set for each slot
      for (final slot in slots) {
        slot['user_id'] = userId;
      }

      final response = await _client
          .from('lecture_slots')
          .insert(slots)
          .select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SUPABASE ERROR - Create Lecture Slots: $e');
      return [];
    }
  }

  /// Update an existing lecture slot.
  Future<bool> updateLectureSlot(String id, Map<String, dynamic> data) async {
    final userId = SupabaseService.userId;
    if (userId == null) {
      debugPrint('Update Lecture Slot Error: user not authenticated');
      return false;
    }

    try {
      // Include user_id to satisfy RLS 'with check' clause
      data['user_id'] = userId;
      await _client.from('lecture_slots').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update Lecture Slot Error: $e');
      return false;
    }
  }

  /// Delete a lecture slot.
  Future<bool> deleteLectureSlot(String id) async {
    try {
      await _client.from('lecture_slots').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete Lecture Slot Error: $e');
      return false;
    }
  }

  /// Delete all lecture slots for a subject.
  Future<bool> deleteLectureSlotsForSubject(String subjectId) async {
    try {
      await _client.from('lecture_slots').delete().eq('subject_id', subjectId);
      return true;
    } catch (e) {
      debugPrint('Delete Lecture Slots for Subject Error: $e');
      return false;
    }
  }

  /// Get a single lecture slot by ID.
  Future<Map<String, dynamic>?> getLectureSlot(String id) async {
    try {
      final response = await _client
          .from('lecture_slots')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Get Lecture Slot Error: $e');
      return null;
    }
  }
}

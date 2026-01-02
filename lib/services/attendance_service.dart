import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing attendance logs in Supabase.
/// Handles CRUD operations for attendance records.
class AttendanceService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get all attendance logs for a list of subject IDs.
  Future<List<Map<String, dynamic>>> getAttendanceLogs(
    List<String> subjectIds,
  ) async {
    if (subjectIds.isEmpty) return [];

    try {
      final response = await _client
          .from('attendance_logs')
          .select()
          .inFilter('subject_id', subjectIds)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Attendance Logs Error: $e');
      return [];
    }
  }

  /// Get attendance logs for a specific subject.
  Future<List<Map<String, dynamic>>> getSubjectAttendance(
    String subjectId,
  ) async {
    try {
      final response = await _client
          .from('attendance_logs')
          .select()
          .eq('subject_id', subjectId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Subject Attendance Error: $e');
      return [];
    }
  }

  /// Upsert (insert or update) an attendance record.
  /// For lecture-based records, uses (subject_id, date, lecture_slot_id).
  /// For legacy records (no lecture slot), uses (subject_id, date).
  Future<Map<String, dynamic>?> upsertAttendance({
    required String subjectId,
    required String date,
    required String status,
    String? lectureSlotId,
    int hoursLogged = 1,
    bool? dutyRequested,
    bool? dutyApproved,
    String? dutyReason,
  }) async {
    try {
      final data = <String, dynamic>{
        'subject_id': subjectId,
        'date': date,
        'status': status,
        'hours_logged': hoursLogged,
      };

      if (lectureSlotId != null) data['lecture_slot_id'] = lectureSlotId;
      if (dutyRequested != null) data['duty_requested'] = dutyRequested;
      if (dutyApproved != null) data['duty_approved'] = dutyApproved;
      if (dutyReason != null) data['duty_reason'] = dutyReason;

      // Use different conflict resolution based on whether lecture_slot_id is present
      // For lecture-based: unique on (subject_id, date, lecture_slot_id)
      // For legacy: unique on (subject_id, date)
      final onConflict = lectureSlotId != null
          ? 'subject_id,date,lecture_slot_id'
          : 'subject_id,date';

      final response = await _client
          .from('attendance_logs')
          .upsert(data, onConflict: onConflict)
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('SUPABASE ERROR - Upsert Attendance: $e');
      debugPrint(
        'Subject ID: $subjectId, Date: $date, Status: $status, Slot: $lectureSlotId',
      );
      return null;
    }
  }

  /// Update an existing attendance record by ID.
  Future<bool> updateAttendance(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('attendance_logs').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Update Attendance Error: $e');
      return false;
    }
  }

  /// Delete an attendance record.
  Future<bool> deleteAttendance(String id) async {
    try {
      await _client.from('attendance_logs').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Delete Attendance Error: $e');
      return false;
    }
  }

  /// Get attendance for a specific date across all subjects.
  Future<List<Map<String, dynamic>>> getAttendanceByDate(
    String date,
    List<String> subjectIds,
  ) async {
    if (subjectIds.isEmpty) return [];

    try {
      final response = await _client
          .from('attendance_logs')
          .select()
          .eq('date', date)
          .inFilter('subject_id', subjectIds);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Attendance By Date Error: $e');
      return [];
    }
  }

  /// Mark attendance as duty leave.
  Future<Map<String, dynamic>?> markDutyLeave({
    required String subjectId,
    required String date,
    required String reason,
    bool approved = true,
  }) async {
    return await upsertAttendance(
      subjectId: subjectId,
      date: date,
      status: 'duty-leave',
      dutyRequested: true,
      dutyApproved: approved,
      dutyReason: reason,
    );
  }

  /// Cancel a duty leave request (revert to absent).
  Future<Map<String, dynamic>?> cancelDutyLeave({
    required String subjectId,
    required String date,
  }) async {
    return await upsertAttendance(
      subjectId: subjectId,
      date: date,
      status: 'absent',
      dutyRequested: false,
      dutyApproved: false,
      dutyReason: null,
    );
  }

  /// Subscribe to real-time attendance changes.
  RealtimeChannel subscribeToAttendance(
    List<String> subjectIds,
    void Function(List<Map<String, dynamic>>) onData,
  ) {
    return _client
        .channel('attendance_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance_logs',
          callback: (payload) async {
            // Refetch attendance logs on any change
            final logs = await getAttendanceLogs(subjectIds);
            onData(logs);
          },
        )
        .subscribe();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../utils/attendance_calculator.dart';
import '../services/supabase_service.dart';
import '../services/subjects_service.dart';
import '../services/attendance_service.dart';
import '../services/lecture_slots_service.dart';
import '../services/notification_service.dart';

/// Attendance provider with Supabase cloud sync.
/// Maintains local cache for performance while syncing with Supabase.
class AttendanceProvider extends ChangeNotifier {
  List<Subject> _subjects = [];
  List<LectureSlot> _lectureSlots = [];
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  // Services
  final SubjectsService _subjectsService = SubjectsService();
  final LectureSlotsService _lectureSlotsService = LectureSlotsService();
  final AttendanceService _attendanceService = AttendanceService();

  // Local storage keys (for offline cache)
  static const String _subjectsKey = 'attendance_subjects';
  static const String _lectureSlotsKey = 'lecture_slots';
  static const String _recordsKey = 'attendance_records';

  List<Subject> get subjects => _subjects;
  List<LectureSlot> get lectureSlots => _lectureSlots;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;

  AttendanceProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load from local cache first for fast startup
    await _loadFromLocalCache();

    // Then sync with Supabase if authenticated
    if (SupabaseService.isAuthenticated) {
      await syncWithSupabase();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load data from local SharedPreferences cache.
  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final subjectsJson = prefs.getString(_subjectsKey);
      if (subjectsJson != null) {
        final List<dynamic> decoded = jsonDecode(subjectsJson);
        _subjects = decoded.map((item) => Subject.fromJson(item)).toList();
      }

      final slotsJson = prefs.getString(_lectureSlotsKey);
      if (slotsJson != null) {
        final List<dynamic> decoded = jsonDecode(slotsJson);
        _lectureSlots = decoded
            .map((item) => LectureSlot.fromJson(item))
            .toList();
      }

      final recordsJson = prefs.getString(_recordsKey);
      if (recordsJson != null) {
        final List<dynamic> decoded = jsonDecode(recordsJson);
        _attendanceRecords = decoded
            .map((item) => AttendanceRecord.fromJson(item))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading from local cache: $e');
    }
  }

  /// Save subjects to local cache.
  Future<void> _saveSubjectsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _subjects.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_subjectsKey, encoded);
    } catch (e) {
      debugPrint('Error saving subjects to cache: $e');
    }
  }

  /// Save lecture slots to local cache.
  Future<void> _saveLectureSlotsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _lectureSlots.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_lectureSlotsKey, encoded);
    } catch (e) {
      debugPrint('Error saving lecture slots to cache: $e');
    }
  }

  /// Save attendance records to local cache.
  Future<void> _saveRecordsToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _attendanceRecords.map((r) => r.toJson()).toList(),
      );
      await prefs.setString(_recordsKey, encoded);
    } catch (e) {
      debugPrint('Error saving records to cache: $e');
    }
  }

  /// Clear all local data (subjects, lecture slots, and records).
  /// Call this on signOut or before signUp to ensure clean state for new user.
  Future<void> clearLocalData() async {
    debugPrint('AttendanceProvider: Clearing local data...');

    // Clear in-memory state
    _subjects = [];
    _lectureSlots = [];
    _attendanceRecords = [];

    // Clear SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subjectsKey);
      await prefs.remove(_lectureSlotsKey);
      await prefs.remove(_recordsKey);
      debugPrint('AttendanceProvider: Local cache cleared');
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
    }

    notifyListeners();
  }

  /// Sync all data with Supabase.
  /// Called on login and can be called to refresh data.
  Future<void> syncWithSupabase() async {
    if (!SupabaseService.isAuthenticated) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Fetch subjects from Supabase
      final subjectsData = await _subjectsService.getSubjects();
      _subjects = subjectsData.map((s) => Subject.fromSupabase(s)).toList();
      await _saveSubjectsToCache();

      // Fetch lecture slots for all subjects
      final slotsData = await _lectureSlotsService.getLectureSlots();
      _lectureSlots = slotsData
          .map((s) => LectureSlot.fromSupabase(s))
          .toList();
      await _saveLectureSlotsToCache();

      // Fetch attendance logs for all subjects
      if (_subjects.isNotEmpty) {
        final subjectIds = _subjects.map((s) => s.id).toList();
        final logsData = await _attendanceService.getAttendanceLogs(subjectIds);
        _attendanceRecords = logsData
            .map((r) => AttendanceRecord.fromSupabase(r))
            .toList();
        await _saveRecordsToCache();
      }

      // Cleanup expired subjects
      await _cleanupExpiredSubjects();
    } catch (e) {
      debugPrint('Error syncing with Supabase: $e');
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Called when user logs in - clear all local/guest data and reload from cloud.
  Future<void> onUserLogin() async {
    // Clear any local/guest data first
    debugPrint(
      'AttendanceProvider: User logged in - clearing guest data and syncing...',
    );
    await clearLocalData();

    // Wait for session to be established (max 2 seconds)
    // This fixes a race condition where onUserLogin is called before
    // SupabaseService.isAuthenticated becomes true
    int attempts = 0;
    while (!SupabaseService.isAuthenticated && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    if (SupabaseService.isAuthenticated) {
      debugPrint('AttendanceProvider: Session confirmed, starting sync...');
      await syncWithSupabase();
    } else {
      debugPrint(
        'AttendanceProvider: Session NOT found after waiting, sync aborted.',
      );
    }
  }

  /// Called when user logs out - clear all data.
  Future<void> onUserLogout() async {
    _subjects = [];
    _attendanceRecords = [];

    // Clear local cache
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subjectsKey);
    await prefs.remove(_recordsKey);

    notifyListeners();
  }

  /// Removes subjects whose endMonth is in the past.
  Future<void> _cleanupExpiredSubjects() async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final expiredSubjectIds = <String>[];

    _subjects.removeWhere((subject) {
      if (subject.endMonth != null && subject.endMonth!.isNotEmpty) {
        if (subject.endMonth!.compareTo(currentMonth) < 0) {
          expiredSubjectIds.add(subject.id);
          return true;
        }
      }
      return false;
    });

    if (expiredSubjectIds.isNotEmpty) {
      _attendanceRecords.removeWhere(
        (record) => expiredSubjectIds.contains(record.subjectId),
      );

      // Delete from Supabase
      for (final id in expiredSubjectIds) {
        await _subjectsService.deleteSubject(id);
      }

      await _saveSubjectsToCache();
      await _saveRecordsToCache();
    }
  }

  // ============================================
  // Subject Management
  // ============================================

  // ============================================
  // Lecture Slot Management
  // ============================================

  /// Get all lecture slots for a given date (matches dayOfWeek).
  /// Returns slots sorted by start time.
  List<LectureSlot> getLectureSlotsForDate(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    // Convert Dart weekday (1-7, Mon-Sun) to JS-style (0-6, Sun-Sat)
    int jsDay = parsedDate.weekday == 7 ? 0 : parsedDate.weekday;

    return _lectureSlots.where((slot) => slot.dayOfWeek == jsDay).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get all lecture slots for a specific subject.
  List<LectureSlot> getLectureSlotsForSubject(String subjectId) {
    return _lectureSlots.where((slot) => slot.subjectId == subjectId).toList()
      ..sort((a, b) {
        final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });
  }

  /// Get attendance status for a specific lecture slot on a given date.
  AttendanceStatus? getLectureSlotStatus(String lectureSlotId, String date) {
    final record = _attendanceRecords.firstWhere(
      (r) => r.lectureSlotId == lectureSlotId && r.date == date,
      orElse: () => AttendanceRecord(
        id: '',
        subjectId: '',
        date: '',
        status: '',
        createdAt: '',
      ),
    );
    if (record.id.isEmpty) return null;
    return AttendanceStatus.values.firstWhere(
      (s) => s.name == record.status.replaceAll('-', ''),
      orElse: () => AttendanceStatus.absent,
    );
  }

  /// Get the subject for a lecture slot.
  Subject? getSubjectForSlot(String lectureSlotId) {
    final slot = _lectureSlots.firstWhere(
      (s) => s.id == lectureSlotId,
      orElse: () => LectureSlot(
        id: '',
        subjectId: '',
        dayOfWeek: 0,
        startTime: '',
        endTime: '',
      ),
    );
    if (slot.id.isEmpty) return null;
    return _subjects.firstWhere(
      (s) => s.id == slot.subjectId,
      orElse: () => Subject(id: '', name: 'Unknown'),
    );
  }

  /// Get attendance status for a specific lecture slot on a date.
  String? getAttendanceForSlot(String lectureSlotId, String date) {
    final record = _attendanceRecords.cast<AttendanceRecord?>().firstWhere(
      (r) => r?.lectureSlotId == lectureSlotId && r?.date == date,
      orElse: () => null,
    );
    return record?.status;
  }

  /// Mark attendance for a specific lecture slot on a date.
  Future<void> markLectureAttendance({
    required String lectureSlotId,
    required String date,
    required String status,
  }) async {
    // Find the lecture slot to get subjectId and duration
    final slot = _lectureSlots.firstWhere(
      (s) => s.id == lectureSlotId,
      orElse: () => throw Exception('Lecture slot not found'),
    );

    if (SupabaseService.isAuthenticated) {
      debugPrint(
        'Marking lecture attendance in Supabase: slot=$lectureSlotId on $date -> $status',
      );
      final result = await _attendanceService.upsertAttendance(
        subjectId: slot.subjectId,
        date: date,
        status: status,
        lectureSlotId: lectureSlotId,
        hoursLogged: slot.durationHours,
      );

      if (result == null) {
        debugPrint('CRITICAL: Failed to save lecture attendance to Supabase');
        throw Exception(
          'Failed to save attendance to database. Please try again.',
        );
      }

      // Update local state with server response
      final serverRecord = AttendanceRecord.fromSupabase(result);
      debugPrint('Lecture attendance saved with ID: ${serverRecord.id}');

      final existingIndex = _attendanceRecords.indexWhere(
        (r) => r.lectureSlotId == lectureSlotId && r.date == date,
      );

      if (existingIndex != -1) {
        _attendanceRecords[existingIndex] = serverRecord;
      } else {
        _attendanceRecords.add(serverRecord);
      }
    } else {
      // Guest mode: store locally
      debugPrint(
        'Marking lecture attendance (Guest Mode): slot=$lectureSlotId on $date -> $status',
      );

      final existingIndex = _attendanceRecords.indexWhere(
        (r) => r.lectureSlotId == lectureSlotId && r.date == date,
      );

      final record = AttendanceRecord(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: slot.subjectId,
        lectureSlotId: lectureSlotId,
        date: date,
        status: status,
        hoursLogged: slot.durationHours,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (existingIndex != -1) {
        _attendanceRecords[existingIndex] = record;
      } else {
        _attendanceRecords.add(record);
      }
    }

    notifyListeners();
    await _saveRecordsToCache();
  }

  /// Legacy method for backward compatibility.
  /// Get today's subjects by checking which subjects have lecture slots on this day.
  List<Subject> getTodaysSubjects(String date) {
    final DateTime parsedDate = DateTime.parse(date);
    int jsDay = parsedDate.weekday == 7 ? 0 : parsedDate.weekday;

    // First check lecture slots (new system)
    final subjectIdsWithSlots = _lectureSlots
        .where((slot) => slot.dayOfWeek == jsDay)
        .map((slot) => slot.subjectId)
        .toSet();

    if (subjectIdsWithSlots.isNotEmpty) {
      return _subjects
          .where((s) => subjectIdsWithSlots.contains(s.id))
          .toList();
    }

    // Fallback to legacy daysOfWeek (migration compatibility)
    return _subjects
        .where((subject) => subject.daysOfWeek.contains(jsDay))
        .toList();
  }

  Future<void> addSubject(Subject subject) async {
    final isAuth = SupabaseService.isAuthenticated;

    if (isAuth) {
      // Authenticated user: Server-first pattern
      final userId = SupabaseService.userId;
      debugPrint('AddSubject: isAuthenticated=$isAuth, userId=$userId');

      debugPrint('Adding subject to Supabase: ${subject.name}');
      final result = await _subjectsService.createSubject(subject.toSupabase());

      if (result == null) {
        debugPrint('CRITICAL: Failed to save subject to Supabase');
        throw Exception(
          'Failed to save subject to database. Please try again.',
        );
      }

      // Use server-generated ID and data
      final serverSubject = Subject.fromSupabase(result);
      debugPrint('Subject created in Supabase with ID: ${serverSubject.id}');
      _subjects.add(serverSubject);
    } else {
      // Guest user: Store locally only with local ID
      debugPrint('AddSubject (Guest Mode): Storing locally - ${subject.name}');
      final localSubject = Subject(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: subject.name,
        initialHoursHeld: subject.initialHoursHeld,
        initialHoursAttended: subject.initialHoursAttended,
        daysOfWeek: subject.daysOfWeek,
        requiredAttendance: subject.requiredAttendance,
        startMonth: subject.startMonth,
        endMonth: subject.endMonth,
      );
      _subjects.add(localSubject);
    }

    notifyListeners();
    await _saveSubjectsToCache();

    // Show native notification
    NotificationService().showSubjectAdded(subject.name);
  }

  /// Add a new subject along with its lecture slots.
  /// This is the preferred method for adding subjects with the lecture-based system.
  Future<void> addSubjectWithSlots(
    Subject subject,
    List<LectureSlot> slots,
  ) async {
    final isAuth = SupabaseService.isAuthenticated;
    String subjectId;

    if (isAuth) {
      // Authenticated user: Server-first pattern
      debugPrint(
        'AddSubjectWithSlots: Adding subject to Supabase: ${subject.name}',
      );
      final result = await _subjectsService.createSubject(subject.toSupabase());

      if (result == null) {
        debugPrint('CRITICAL: Failed to save subject to Supabase');
        throw Exception(
          'Failed to save subject to database. Please try again.',
        );
      }

      // Use server-generated ID
      final serverSubject = Subject.fromSupabase(result);
      subjectId = serverSubject.id;
      debugPrint('Subject created in Supabase with ID: $subjectId');
      _subjects.add(serverSubject);

      // Now create lecture slots with the server-generated subject ID
      if (slots.isNotEmpty) {
        final slotsWithSubjectId = slots
            .map((s) => s.copyWith(subjectId: subjectId).toSupabase())
            .toList();
        final createdSlots = await _lectureSlotsService.createLectureSlots(
          slotsWithSubjectId,
        );
        _lectureSlots.addAll(
          createdSlots.map((s) => LectureSlot.fromSupabase(s)),
        );
        await _saveLectureSlotsToCache();
      }
    } else {
      // Guest mode: Store locally
      debugPrint(
        'AddSubjectWithSlots (Guest Mode): Storing locally - ${subject.name}',
      );
      subjectId = 'local_${DateTime.now().millisecondsSinceEpoch}';

      final localSubject = Subject(
        id: subjectId,
        name: subject.name,
        initialHoursHeld: subject.initialHoursHeld,
        initialHoursAttended: subject.initialHoursAttended,
        daysOfWeek: subject.daysOfWeek,
        requiredAttendance: subject.requiredAttendance,
        startMonth: subject.startMonth,
        endMonth: subject.endMonth,
      );
      _subjects.add(localSubject);

      // Create local lecture slots
      for (int i = 0; i < slots.length; i++) {
        _lectureSlots.add(
          slots[i].copyWith(
            id: 'local_slot_${DateTime.now().millisecondsSinceEpoch}_$i',
            subjectId: subjectId,
          ),
        );
      }
      await _saveLectureSlotsToCache();
    }

    notifyListeners();
    await _saveSubjectsToCache();
    NotificationService().showSubjectAdded(subject.name);
  }

  /// Update lecture slots for an existing subject.
  /// Deletes existing slots and creates new ones.
  /// Update lecture slots for an existing subject.
  /// Smarter update: preserves existing slots (and their IDs) to keep attendance links.
  Future<void> updateLectureSlots(
    String subjectId,
    List<LectureSlot> newSlots,
  ) async {
    // 1. Get current slots for this subject
    final currentSlots = _lectureSlots
        .where((s) => s.subjectId == subjectId)
        .toList();

    // 2. Identify slots to delete (exist in current but not in new)
    // We match by ID if the new slot has a real ID, otherwise we treat it as new.
    // Since the UI might pass ephemeral IDs for new slots, reliable matching is tricky.
    // Strategy:
    // - If newSlot has a valid ID (from DB/local) that exists in currentSlots, it's an UPDATE.
    // - If not, it's a CREATE.
    // - Any currentSlot ID not found in newSlots list is a DELETE.

    final newSlotIds = newSlots.map((s) => s.id).toSet();
    final slotsToDelete = currentSlots
        .where((s) => !newSlotIds.contains(s.id))
        .toList();
    final slotsToUpdate = newSlots
        .where((s) => currentSlots.any((curr) => curr.id == s.id))
        .toList();
    final slotsToCreate = newSlots
        .where((s) => !currentSlots.any((curr) => curr.id == s.id))
        .toList();

    if (SupabaseService.isAuthenticated) {
      // --- SERVER SYNC ---

      // A. Delete removed slots
      for (final slot in slotsToDelete) {
        await _lectureSlotsService.deleteLectureSlot(slot.id);
        _lectureSlots.removeWhere((s) => s.id == slot.id);
      }

      // B. Update existing slots
      for (final slot in slotsToUpdate) {
        await _lectureSlotsService.updateLectureSlot(
          slot.id,
          slot.toSupabase(),
        );
        final index = _lectureSlots.indexWhere((s) => s.id == slot.id);
        if (index != -1) {
          _lectureSlots[index] = slot;
        }
      }

      // C. Create new slots
      if (slotsToCreate.isNotEmpty) {
        final slotsData = slotsToCreate
            .map((s) => s.copyWith(subjectId: subjectId).toSupabase())
            .toList();
        final createdSlots = await _lectureSlotsService.createLectureSlots(
          slotsData,
        );
        _lectureSlots.addAll(
          createdSlots.map((s) => LectureSlot.fromSupabase(s)),
        );
      }
    } else {
      // --- LOCAL (GUEST) ---

      // A. Delete removed slots
      for (final slot in slotsToDelete) {
        _lectureSlots.removeWhere((s) => s.id == slot.id);
      }

      // B. Update existing slots
      for (final slot in slotsToUpdate) {
        final index = _lectureSlots.indexWhere((s) => s.id == slot.id);
        if (index != -1) {
          _lectureSlots[index] = slot;
        }
      }

      // C. Create new slots
      for (int i = 0; i < slotsToCreate.length; i++) {
        _lectureSlots.add(
          slotsToCreate[i].copyWith(
            id: 'local_slot_${DateTime.now().millisecondsSinceEpoch}_$i',
            subjectId: subjectId,
          ),
        );
      }
    }

    await _saveLectureSlotsToCache();
    notifyListeners();
  }

  Future<void> updateSubject(Subject subject) async {
    if (SupabaseService.isAuthenticated) {
      // Authenticated user: Sync with server
      final success = await _subjectsService.updateSubject(
        subject.id,
        subject.toSupabase(),
      );

      if (!success) {
        throw Exception('Failed to update subject in database');
      }
    } else {
      // Guest user: Update locally only
      debugPrint(
        'UpdateSubject (Guest Mode): Updating locally - ${subject.name}',
      );
    }

    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      notifyListeners();
      await _saveSubjectsToCache();
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    if (SupabaseService.isAuthenticated) {
      // Authenticated user: Delete from server first
      final success = await _subjectsService.deleteSubject(subjectId);
      if (!success) {
        throw Exception('Failed to delete subject from database');
      }
    } else {
      // Guest user: Delete locally only
      debugPrint('DeleteSubject (Guest Mode): Deleting locally - $subjectId');
    }

    _subjects.removeWhere((s) => s.id == subjectId);
    _attendanceRecords.removeWhere((r) => r.subjectId == subjectId);
    notifyListeners();
    await _saveSubjectsToCache();
    await _saveRecordsToCache();
  }

  // ============================================
  // Attendance Management
  // ============================================

  SubjectAttendanceData getSubjectAttendanceData(String subjectId) {
    final subjectRecords = _attendanceRecords
        .where((r) => r.subjectId == subjectId)
        .toList();
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(id: 'temp', name: 'Temp', daysOfWeek: []),
    );

    if (subject.id == 'temp') {
      return SubjectAttendanceData(
        classesAttended: 0,
        classesHeld: 0,
        attendancePercentage: 0,
        isAtRisk: false,
        physicalClassesAttended: 0,
        physicalAttendancePercentage: 0,
      );
    }

    final recordsPresent = subjectRecords
        .where((r) => r.status == 'present' || r.status == 'duty-leave')
        .length;
    final recordsTotal = subjectRecords.length;

    final initialClassesHeld = subject.classesHeld;
    final initialClassesAttended = subject.classesAttended;

    final finalClassesHeld = initialClassesHeld + recordsTotal;
    final finalClassesAttended = initialClassesAttended + recordsPresent;

    final attendancePercentage = finalClassesHeld > 0
        ? (finalClassesAttended / finalClassesHeld) * 100
        : 0.0;
    final isAtRisk = attendancePercentage < subject.requiredAttendance;

    return SubjectAttendanceData(
      classesAttended: finalClassesAttended,
      classesHeld: finalClassesHeld,
      attendancePercentage: attendancePercentage,
      isAtRisk: isAtRisk,
      physicalClassesAttended:
          initialClassesAttended +
          subjectRecords.where((r) => r.status == 'present').length,
      physicalAttendancePercentage: finalClassesHeld > 0
          ? ((initialClassesAttended +
                        subjectRecords
                            .where((r) => r.status == 'present')
                            .length) /
                    finalClassesHeld) *
                100
          : 0.0,
    );
  }

  AttendanceStats getAttendanceStats() {
    final totalPresent = _attendanceRecords
        .where((r) => r.status == 'present' || r.status == 'duty-leave')
        .length;
    final totalAbsent = _attendanceRecords
        .where((r) => r.status == 'absent')
        .length;
    final totalDutyLeave = _attendanceRecords
        .where((r) => r.status == 'duty-leave')
        .length;
    final totalRecords = _attendanceRecords.length;

    int totalClassesHeld = 0;
    int totalClassesAttended = 0;

    for (var subject in _subjects) {
      final data = getSubjectAttendanceData(subject.id);
      totalClassesHeld += data.classesHeld;
      totalClassesAttended += data.classesAttended;
    }

    final attendancePercentage = totalClassesHeld > 0
        ? (totalClassesAttended / totalClassesHeld) * 100
        : 0.0;

    int totalPhysicalAttended = 0;
    for (var subject in _subjects) {
      final data = getSubjectAttendanceData(subject.id);
      totalPhysicalAttended += data.physicalClassesAttended;
    }

    final physicalAttendancePercentage = totalClassesHeld > 0
        ? (totalPhysicalAttended / totalClassesHeld) * 100
        : 0.0;

    return AttendanceStats(
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalDutyLeave: totalDutyLeave,
      totalRecords: totalRecords,
      totalClassesHeld: totalClassesHeld,
      totalClassesAttended: totalClassesAttended,
      attendancePercentage: attendancePercentage,
      physicalAttendancePercentage: physicalAttendancePercentage,
    );
  }

  Future<void> markAttendance(
    String subjectId,
    String date,
    String status,
  ) async {
    if (SupabaseService.isAuthenticated) {
      // Authenticated user: Server-first pattern
      debugPrint(
        'Marking attendance in Supabase: $subjectId on $date -> $status',
      );
      final result = await _attendanceService.upsertAttendance(
        subjectId: subjectId,
        date: date,
        status: status,
      );

      if (result == null) {
        debugPrint('CRITICAL: Failed to save attendance to Supabase');
        throw Exception(
          'Failed to save attendance to database. Please try again.',
        );
      }

      // Update local state with server response
      final serverRecord = AttendanceRecord.fromSupabase(result);
      debugPrint('Attendance saved in Supabase with ID: ${serverRecord.id}');

      final existingIndex = _attendanceRecords.indexWhere(
        (r) => r.subjectId == subjectId && r.date == date,
      );

      if (existingIndex != -1) {
        _attendanceRecords[existingIndex] = serverRecord;
      } else {
        _attendanceRecords.add(serverRecord);
      }
    } else {
      // Guest user: Store locally only
      debugPrint(
        'Marking attendance (Guest Mode): $subjectId on $date -> $status',
      );

      final existingIndex = _attendanceRecords.indexWhere(
        (r) => r.subjectId == subjectId && r.date == date,
      );

      final localRecord = AttendanceRecord(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        date: date,
        status: status,
        createdAt: DateTime.now().toIso8601String().split('T')[0],
        updatedAt: DateTime.now().toIso8601String().split('T')[0],
        dutyRequested: false,
        dutyApproved: false,
      );

      if (existingIndex != -1) {
        _attendanceRecords[existingIndex] = localRecord;
      } else {
        _attendanceRecords.add(localRecord);
      }
    }

    notifyListeners();
    await _saveRecordsToCache();
  }

  // ============================================
  // Duty Leave Workflow
  // ============================================

  List<AttendanceRecord> listAbsentRecords({String? subjectId}) {
    return _attendanceRecords.where((r) {
      final subjectMatch = subjectId == null || r.subjectId == subjectId;
      final isAbsent = r.status == 'absent';
      return subjectMatch && isAbsent && !r.dutyApproved;
    }).toList();
  }

  List<AttendanceRecord> listAllAbsentRecordsAcrossSubjects() {
    return _attendanceRecords.where((r) {
      return r.status == 'absent' && !r.dutyApproved;
    }).toList();
  }

  List<AttendanceRecord> listApprovedDutyLeaves() {
    return _attendanceRecords.where((r) {
      return r.status == 'duty-leave' && r.dutyApproved;
    }).toList();
  }

  Future<void> requestDutyLeave(
    String subjectId,
    String date,
    String reason,
  ) async {
    if (SupabaseService.isAuthenticated) {
      // Server first
      final result = await _attendanceService.upsertAttendance(
        subjectId: subjectId,
        date: date,
        status: 'absent',
        dutyRequested: true,
        dutyReason: reason,
      );

      if (result == null) {
        throw Exception('Failed to request duty leave in database');
      }

      final serverRecord = AttendanceRecord.fromSupabase(result);
      final index = _attendanceRecords.indexWhere(
        (r) => r.subjectId == subjectId && r.date == date,
      );

      if (index != -1) {
        _attendanceRecords[index] = serverRecord;
      } else {
        _attendanceRecords.add(serverRecord);
      }
    } else {
      // Guest mode: Update locally
      debugPrint(
        'RequestDutyLeave (Guest Mode): $subjectId on $date - $reason',
      );

      final index = _attendanceRecords.indexWhere(
        (r) => r.subjectId == subjectId && r.date == date,
      );

      final localRecord = AttendanceRecord(
        id: index != -1
            ? _attendanceRecords[index].id
            : 'local_${DateTime.now().millisecondsSinceEpoch}',
        subjectId: subjectId,
        date: date,
        status: 'absent',
        dutyRequested: true,
        dutyReason: reason,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (index != -1) {
        _attendanceRecords[index] = localRecord;
      } else {
        _attendanceRecords.add(localRecord);
      }
    }

    notifyListeners();
    await _saveRecordsToCache();
  }

  Future<void> approveDutyLeave(String subjectId, String date) async {
    final index = _attendanceRecords.indexWhere(
      (r) => r.subjectId == subjectId && r.date == date,
    );
    final reason = index != -1
        ? _attendanceRecords[index].dutyReason ?? ''
        : '';

    if (SupabaseService.isAuthenticated) {
      // Server first
      final result = await _attendanceService.markDutyLeave(
        subjectId: subjectId,
        date: date,
        reason: reason,
        approved: true,
      );

      if (result == null) {
        throw Exception('Failed to approve duty leave in database');
      }

      if (index != -1) {
        _attendanceRecords[index] = AttendanceRecord.fromSupabase(result);
      }
    } else {
      // Guest mode: Update locally
      debugPrint('ApproveDutyLeave (Guest Mode): $subjectId on $date');

      if (index != -1) {
        final existingRecord = _attendanceRecords[index];
        _attendanceRecords[index] = AttendanceRecord(
          id: existingRecord.id,
          subjectId: subjectId,
          date: date,
          status: 'duty-leave',
          dutyRequested: true,
          dutyApproved: true,
          dutyReason: reason,
          createdAt: existingRecord.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
    }

    notifyListeners();
    await _saveRecordsToCache();

    // Show native notification
    final subjectName = _subjects
        .firstWhere(
          (s) => s.id == subjectId,
          orElse: () => Subject(id: '', name: 'Subject', daysOfWeek: []),
        )
        .name;
    NotificationService().showDutyLeaveApplied(
      subjectName: subjectName,
      date: date,
    );
  }

  Future<void> cancelDutyRequest(String subjectId, String date) async {
    final index = _attendanceRecords.indexWhere(
      (r) => r.subjectId == subjectId && r.date == date,
    );

    if (SupabaseService.isAuthenticated) {
      // Server first
      final result = await _attendanceService.cancelDutyLeave(
        subjectId: subjectId,
        date: date,
      );

      if (result == null) {
        throw Exception('Failed to cancel duty leave in database');
      }

      if (index != -1) {
        _attendanceRecords[index] = AttendanceRecord.fromSupabase(result);
      }
    } else {
      // Guest mode: Update locally
      debugPrint('CancelDutyRequest (Guest Mode): $subjectId on $date');

      if (index != -1) {
        final existingRecord = _attendanceRecords[index];
        _attendanceRecords[index] = AttendanceRecord(
          id: existingRecord.id,
          subjectId: subjectId,
          date: date,
          status: 'absent',
          dutyRequested: false,
          dutyApproved: false,
          dutyReason: null,
          createdAt: existingRecord.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
    }

    notifyListeners();
    await _saveRecordsToCache();
  }

  Future<void> markAbsent(String subjectId, String date) async {
    await markAttendance(subjectId, date, 'absent');
  }

  // ============================================
  // Utility Methods
  // ============================================

  AttendanceStatus? getStatusOnDate(String subjectId, String date) {
    try {
      final record = _attendanceRecords.firstWhere(
        (r) => r.subjectId == subjectId && r.date == date,
      );
      return record.statusEnum;
    } catch (_) {
      return null;
    }
  }

  int computeClassesHeld(String subjectId) {
    final data = getSubjectAttendanceData(subjectId);
    return data.classesHeld;
  }

  int computeClassesAttendedWithoutDuty(String subjectId) {
    final data = getSubjectAttendanceData(subjectId);
    return data.physicalClassesAttended;
  }

  int computeClassesAttendedWithDuty(String subjectId) {
    final data = getSubjectAttendanceData(subjectId);
    return data.classesAttended;
  }

  Map<String, double> computePercentWithAndWithoutDuty(String subjectId) {
    final data = getSubjectAttendanceData(subjectId);
    return {
      'withoutDuty': data.physicalAttendancePercentage,
      'withDuty': data.attendancePercentage,
    };
  }

  int getClassesNeeded(String subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(id: '', name: '', daysOfWeek: []),
    );

    if (subject.id.isEmpty) return 0;

    final attendanceData = getSubjectAttendanceData(subjectId);
    return calculateClassesNeeded(
      attended: attendanceData.classesAttended,
      total: attendanceData.classesHeld,
      target: subject.requiredAttendance,
    );
  }

  Future<void> updateRecordStatus(
    String recordId,
    String newStatus, {
    String? reason,
  }) async {
    if (!SupabaseService.isAuthenticated) {
      throw Exception('You must be logged in to update attendance');
    }

    // Server first
    final success = await _attendanceService.updateAttendance(recordId, {
      'status': newStatus,
      if (reason != null) 'reason': reason,
    });

    if (!success) {
      throw Exception('Failed to update record in database');
    }

    // We ideally should fetch the updated record, but since we know what we updated:
    final index = _attendanceRecords.indexWhere((r) => r.id == recordId);
    if (index != -1) {
      final record = _attendanceRecords[index];
      _attendanceRecords[index] = record.copyWith(
        status: newStatus,
        reason: reason,
        updatedAt: DateTime.now().toIso8601String().split('T')[0],
      );
      notifyListeners();
      await _saveRecordsToCache();
    }
  }

  Future<void> ensureTodayRecord(String subjectId) async {
    // No-op - records are created on demand
  }

  // ============================================
  // Data Export/Import
  // ============================================

  Map<String, dynamic> exportData() {
    return {
      'subjects': _subjects.map((s) => s.toJson()).toList(),
      'attendanceRecords': _attendanceRecords.map((r) => r.toJson()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    try {
      final subjectsData = data['subjects'] as List<dynamic>;
      final recordsData = data['attendanceRecords'] as List<dynamic>;

      _subjects = subjectsData.map((item) => Subject.fromJson(item)).toList();
      _attendanceRecords = recordsData
          .map((item) => AttendanceRecord.fromJson(item))
          .toList();

      await _saveSubjectsToCache();
      await _saveRecordsToCache();

      // Sync imported data to Supabase
      if (SupabaseService.isAuthenticated) {
        for (final subject in _subjects) {
          await _subjectsService.createSubject(subject.toSupabase());
        }
        // Note: Attendance records will be synced with new subject IDs
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  Future<void> clearAllData() async {
    // Delete from Supabase first
    if (SupabaseService.isAuthenticated) {
      for (final subject in _subjects) {
        await _subjectsService.deleteSubject(subject.id);
      }
    }

    _subjects.clear();
    _attendanceRecords.clear();
    await _saveSubjectsToCache();
    await _saveRecordsToCache();
    notifyListeners();
  }
}

class SubjectAttendanceData {
  final int classesAttended;
  final int classesHeld;
  final double attendancePercentage;
  final bool isAtRisk;
  final int physicalClassesAttended;
  final double physicalAttendancePercentage;

  SubjectAttendanceData({
    required this.classesAttended,
    required this.classesHeld,
    required this.attendancePercentage,
    required this.isAtRisk,
    this.physicalClassesAttended = 0,
    this.physicalAttendancePercentage = 0.0,
  });
}

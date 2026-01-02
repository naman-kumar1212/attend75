import 'package:flutter/material.dart';

/// Days of the week for lecture scheduling.
enum Weekday {
  monday(1, 'Monday', 'Mon'),
  tuesday(2, 'Tuesday', 'Tue'),
  wednesday(3, 'Wednesday', 'Wed'),
  thursday(4, 'Thursday', 'Thu'),
  friday(5, 'Friday', 'Fri'),
  saturday(6, 'Saturday', 'Sat'),
  sunday(0, 'Sunday', 'Sun');

  final int value;
  final String fullName;
  final String shortName;

  const Weekday(this.value, this.fullName, this.shortName);

  /// Convert from integer (0-6) to Weekday
  static Weekday fromInt(int value) {
    return Weekday.values.firstWhere(
      (d) => d.value == value,
      orElse: () => Weekday.monday,
    );
  }
}

/// Represents a recurring lecture slot in the weekly timetable.
/// Each subject can have multiple lecture slots (e.g., Math on Mon 9:00-10:00 and Wed 2:00-4:00).
class LectureSlot {
  final String id;
  final String subjectId;
  final int dayOfWeek; // 0=Sunday, 1=Monday, ...
  final String startTime; // "HH:mm" format (e.g., "09:00")
  final String endTime; // "HH:mm" format (e.g., "10:00")
  final int durationHours; // 1 or 2 (credit-hours for this slot)

  LectureSlot({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.durationHours = 1,
  });

  /// Create a LectureSlot from TimeOfDay values
  factory LectureSlot.fromTimeOfDay({
    required String id,
    required String subjectId,
    required Weekday weekday,
    required TimeOfDay startTimeOfDay,
    required int durationHours,
  }) {
    final start = _formatTimeOfDay(startTimeOfDay);
    final endTimeOfDay = TimeOfDay(
      hour: startTimeOfDay.hour + durationHours,
      minute: startTimeOfDay.minute,
    );
    final end = _formatTimeOfDay(endTimeOfDay);

    return LectureSlot(
      id: id,
      subjectId: subjectId,
      dayOfWeek: weekday.value,
      startTime: start,
      endTime: end,
      durationHours: durationHours,
    );
  }

  /// Get start time as TimeOfDay
  TimeOfDay get startTimeOfDay => _parseTimeOfDay(startTime);

  /// Get end time as TimeOfDay
  TimeOfDay get endTimeOfDay => _parseTimeOfDay(endTime);

  /// Get weekday enum
  Weekday get weekday => Weekday.fromInt(dayOfWeek);

  /// Check if this slot overlaps with another on the same day
  bool overlaps(LectureSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;

    final thisStart = _timeToMinutes(startTime);
    final thisEnd = _timeToMinutes(endTime);
    final otherStart = _timeToMinutes(other.startTime);
    final otherEnd = _timeToMinutes(other.endTime);

    return thisStart < otherEnd && otherStart < thisEnd;
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'durationHours': durationHours,
    };
  }

  factory LectureSlot.fromJson(Map<String, dynamic> json) {
    return LectureSlot(
      id: json['id'],
      subjectId: json['subjectId'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      durationHours: json['durationHours'] ?? 1,
    );
  }

  factory LectureSlot.fromSupabase(Map<String, dynamic> json) {
    return LectureSlot(
      id: json['id'],
      subjectId: json['subject_id'],
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationHours: json['duration_hours'] ?? 1,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'subject_id': subjectId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
    };
  }

  LectureSlot copyWith({
    String? id,
    String? subjectId,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? durationHours,
  }) {
    return LectureSlot(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
    );
  }

  /// Update with new TimeOfDay values
  LectureSlot copyWithTimeOfDay({
    TimeOfDay? startTimeOfDay,
    int? durationHours,
  }) {
    final newDuration = durationHours ?? this.durationHours;
    final newStart = startTimeOfDay ?? this.startTimeOfDay;
    final newEnd = TimeOfDay(
      hour: newStart.hour + newDuration,
      minute: newStart.minute,
    );

    return LectureSlot(
      id: id,
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: _formatTimeOfDay(newStart),
      endTime: _formatTimeOfDay(newEnd),
      durationHours: newDuration,
    );
  }

  /// Get day abbreviation (e.g., "Mon", "Tue")
  String get dayAbbreviation {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return dayNames[dayOfWeek % 7];
  }

  /// Format time range for display (e.g., "09:00 - 10:00")
  String get timeRange {
    final start = _formatTimeAmPm(startTime);
    final end = _formatTimeAmPm(endTime);
    return '$start - $end';
  }

  String _formatTimeAmPm(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      final period = hour >= 12 ? 'PM' : 'AM';
      var hour12 = hour > 12 ? hour - 12 : hour;
      if (hour12 == 0) hour12 = 12;

      return '${hour12.toString().padLeft(2, '0')}:$minute $period';
    } catch (e) {
      return time;
    }
  }
}

class Subject {
  final String id;
  final String name;

  /// Legacy field: Initial hours held before app tracking (for migration).
  /// Renamed from classesHeld to clarify it represents hours, not individual classes.
  final int initialHoursHeld;

  /// Legacy field: Initial hours attended before app tracking (for migration).
  final int initialHoursAttended;

  /// Legacy field: Days of week (kept for backward compatibility during migration).
  /// New subjects should use LectureSlot instead.
  final List<int> daysOfWeek;
  final double requiredAttendance;
  final String? startMonth; // Format: "YYYY-MM"
  final String? endMonth; // Format: "YYYY-MM"

  Subject({
    required this.id,
    required this.name,
    this.initialHoursHeld = 0,
    this.initialHoursAttended = 0,
    this.daysOfWeek = const [],
    this.requiredAttendance = 75.0,
    this.startMonth,
    this.endMonth,
  });

  // Backward compatibility getters
  int get classesHeld => initialHoursHeld;
  int get classesAttended => initialHoursAttended;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'classesHeld': initialHoursHeld,
      'classesAttended': initialHoursAttended,
      'daysOfWeek': daysOfWeek,
      'requiredAttendance': requiredAttendance,
      'startMonth': startMonth,
      'endMonth': endMonth,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      initialHoursHeld: json['classesHeld'] ?? json['initialHoursHeld'] ?? 0,
      initialHoursAttended:
          json['classesAttended'] ?? json['initialHoursAttended'] ?? 0,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : const [],
      requiredAttendance:
          (json['requiredAttendance'] as num?)?.toDouble() ?? 75.0,
      startMonth: json['startMonth'],
      endMonth: json['endMonth'],
    );
  }

  /// Create a Subject from Supabase database row.
  factory Subject.fromSupabase(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      initialHoursHeld:
          json['initial_hours_held'] ?? json['total_classes'] ?? 0,
      initialHoursAttended:
          json['initial_hours_attended'] ?? json['attended_classes'] ?? 0,
      daysOfWeek: json['days_of_week'] != null
          ? List<int>.from(json['days_of_week'])
          : const [],
      requiredAttendance:
          (json['required_attendance'] as num?)?.toDouble() ?? 75.0,
      startMonth: json['start_month'],
      endMonth: json['end_month'],
    );
  }

  /// Convert to Supabase database format.
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'initial_hours_held': initialHoursHeld,
      'initial_hours_attended': initialHoursAttended,
      'days_of_week': daysOfWeek,
      'required_attendance': requiredAttendance,
      'start_month': startMonth,
      'end_month': endMonth,
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    int? initialHoursHeld,
    int? initialHoursAttended,
    List<int>? daysOfWeek,
    double? requiredAttendance,
    String? startMonth,
    String? endMonth,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      initialHoursHeld: initialHoursHeld ?? this.initialHoursHeld,
      initialHoursAttended: initialHoursAttended ?? this.initialHoursAttended,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      requiredAttendance: requiredAttendance ?? this.requiredAttendance,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
    );
  }
}

enum AttendanceStatus { present, absent, dutyLeave }

class AttendanceRecord {
  final String id;
  final String subjectId;

  /// FK to LectureSlot. Null for legacy records (pre-lecture-slot migration).
  final String? lectureSlotId;
  final String date; // YYYY-MM-DD
  final String status; // 'present', 'absent', 'duty-leave'
  /// Hours logged for this attendance (from LectureSlot.durationHours).
  /// Defaults to 1 for legacy records.
  final int hoursLogged;
  final String createdAt;
  final String? updatedAt;
  final String? reason;
  final bool dutyRequested;
  final bool dutyApproved;
  final String? dutyReason;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    this.lectureSlotId,
    required this.date,
    required this.status,
    this.hoursLogged = 1,
    required this.createdAt,
    this.updatedAt,
    this.reason,
    this.dutyRequested = false,
    this.dutyApproved = false,
    this.dutyReason,
  });

  // Helper to get status as Enum
  AttendanceStatus get statusEnum {
    switch (status) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'duty-leave':
        return AttendanceStatus.dutyLeave;
      default:
        return AttendanceStatus.absent;
    }
  }

  static String statusToString(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.dutyLeave:
        return 'duty-leave';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'lectureSlotId': lectureSlotId,
      'date': date,
      'status': status,
      'hoursLogged': hoursLogged,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'reason': reason,
      'dutyRequested': dutyRequested,
      'dutyApproved': dutyApproved,
      'dutyReason': dutyReason,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      subjectId: json['subjectId'],
      lectureSlotId: json['lectureSlotId'],
      date: json['date'],
      status: json['status'],
      hoursLogged: json['hoursLogged'] ?? 1,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      reason: json['reason'],
      dutyRequested: json['dutyRequested'] ?? false,
      dutyApproved: json['dutyApproved'] ?? false,
      dutyReason: json['dutyReason'],
    );
  }

  /// Create an AttendanceRecord from Supabase database row.
  factory AttendanceRecord.fromSupabase(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'],
      subjectId: json['subject_id'],
      lectureSlotId: json['lecture_slot_id'],
      date: json['date'],
      status: json['status'],
      hoursLogged: json['hours_logged'] ?? 1,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
      reason: json['reason'],
      dutyRequested: json['duty_requested'] ?? false,
      dutyApproved: json['duty_approved'] ?? false,
      dutyReason: json['duty_reason'],
    );
  }

  /// Convert to Supabase database format.
  Map<String, dynamic> toSupabase() {
    return {
      'subject_id': subjectId,
      'lecture_slot_id': lectureSlotId,
      'date': date,
      'status': status,
      'hours_logged': hoursLogged,
      'duty_requested': dutyRequested,
      'duty_approved': dutyApproved,
      'duty_reason': dutyReason,
    };
  }

  DateTime get dateTime => DateTime.parse(date);

  AttendanceRecord copyWith({
    String? id,
    String? subjectId,
    String? lectureSlotId,
    String? date,
    String? status,
    int? hoursLogged,
    String? createdAt,
    String? updatedAt,
    String? reason,
    bool? dutyRequested,
    bool? dutyApproved,
    String? dutyReason,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      lectureSlotId: lectureSlotId ?? this.lectureSlotId,
      date: date ?? this.date,
      status: status ?? this.status,
      hoursLogged: hoursLogged ?? this.hoursLogged,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reason: reason ?? this.reason,
      dutyRequested: dutyRequested ?? this.dutyRequested,
      dutyApproved: dutyApproved ?? this.dutyApproved,
      dutyReason: dutyReason ?? this.dutyReason,
    );
  }
}

class AttendanceStats {
  final int totalPresent; // Physical present
  final int totalAbsent;
  final int totalDutyLeave;
  final int totalRecords;
  final int totalClassesHeld;
  final int totalClassesAttended; // Official (Present + Duty Leave)
  final double attendancePercentage; // Official Percentage
  final double physicalAttendancePercentage; // Physical Percentage

  AttendanceStats({
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalDutyLeave,
    required this.totalRecords,
    required this.totalClassesHeld,
    required this.totalClassesAttended,
    required this.attendancePercentage,
    required this.physicalAttendancePercentage,
  });
}

// Helper extension to get day abbreviations from dayOfWeek integers
extension SubjectDaysExtension on Subject {
  List<String> get days {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return daysOfWeek.map((dayNum) => dayNames[dayNum % 7]).toList();
  }

  String get daysString {
    return days.join(', ');
  }
}

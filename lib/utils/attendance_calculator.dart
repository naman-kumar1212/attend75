import 'dart:math';
import '../models.dart';

/// Result of attendance calculation showing skip/attend recommendations
class AttendanceAdvice {
  final double currentPercentage;
  final bool isAboveThreshold;
  final int classesToSkip;
  final int classesToAttend;
  final String message;

  AttendanceAdvice({
    required this.currentPercentage,
    required this.isAboveThreshold,
    required this.classesToSkip,
    required this.classesToAttend,
    required this.message,
  });
}

/// Calculate attendance advice for a subject
///
/// Parameters:
/// - attended: number of classes attended
/// - totalHeld: number of classes held
/// - classesPerWeek: how many times this subject occurs weekly
/// - threshold: required attendance percentage (default 75%)
/// Calculate how many classes can be safely skipped while maintaining target attendance
int calculateBunkableClasses({
  required int attended,
  required int total,
  required double target,
}) {
  if (target <= 0) return 999;
  if (target > 100) return 0;

  final thresholdDecimal = target / 100;
  // Formula: maxSkippable = floor(attended / threshold - total)
  return max(0, (attended / thresholdDecimal - total).floor());
}

/// Calculate how many consecutive classes needed to reach target attendance
int calculateClassesNeeded({
  required int attended,
  required int total,
  required double target,
}) {
  if (target <= 0) return 0;
  // If target is 100% and we've missed a class, it's impossible (unless we reset)
  // For this logic, we'll return a high number or handled elsewhere,
  // but standard formula handles it usually if denominator != 0
  if (target >= 100 && attended < total) return 999;

  final thresholdDecimal = target / 100;
  final current = total > 0 ? (attended / total) * 100 : 0;

  if (current >= target) return 0;

  // Formula: X >= (R*T - A) / (1 - R)
  final numerator = thresholdDecimal * total - attended;
  final denominator = 1 - thresholdDecimal;

  if (denominator == 0) return 999;

  return max(0, (numerator / denominator).ceil());
}

AttendanceAdvice calculateAttendanceAdvice({
  required int attended,
  required int totalHeld,
  required int classesPerWeek,
  double threshold = 75.0,
}) {
  // Avoid division by zero
  if (totalHeld == 0 || classesPerWeek == 0) {
    return AttendanceAdvice(
      currentPercentage: 0.0,
      isAboveThreshold: false,
      classesToSkip: 0,
      classesToAttend: 0,
      message: 'No classes held yet',
    );
  }

  // Calculate current attendance percentage
  final currentPercentage = (attended / totalHeld) * 100;
  final isAboveThreshold = currentPercentage >= threshold;

  if (isAboveThreshold) {
    final maxSkippable = calculateBunkableClasses(
      attended: attended,
      total: totalHeld,
      target: threshold,
    );
    return AttendanceAdvice(
      currentPercentage: currentPercentage,
      isAboveThreshold: true,
      classesToSkip: maxSkippable,
      classesToAttend: 0,
      message: maxSkippable > 0
          ? 'You can skip $maxSkippable classes and stay above ${threshold.round()}%'
          : 'Attend all remaining classes to maintain ${threshold.round()}%',
    );
  } else {
    final classesToAttend = calculateClassesNeeded(
      attended: attended,
      total: totalHeld,
      target: threshold,
    );
    return AttendanceAdvice(
      currentPercentage: currentPercentage,
      isAboveThreshold: false,
      classesToSkip: 0,
      classesToAttend: classesToAttend,
      message: classesToAttend > 0
          ? 'Attend $classesToAttend more classes to reach ${threshold.round()}%'
          : 'Almost there! Stay consistent',
    );
  }
}

/// Extension to calculate classes per week from a Subject
extension SubjectAttendanceExtension on Subject {
  int get classesPerWeek => daysOfWeek.length;

  AttendanceAdvice getAttendanceAdvice() {
    return calculateAttendanceAdvice(
      attended: classesAttended,
      totalHeld: classesHeld,
      classesPerWeek: classesPerWeek,
      threshold: requiredAttendance,
    );
  }
}

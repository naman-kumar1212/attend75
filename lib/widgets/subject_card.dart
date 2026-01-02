import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/attendance_provider.dart';
import '../models.dart';

import '../utils/snackbar_helper.dart';

class SubjectCard extends StatefulWidget {
  final Subject subject;
  final AttendanceRecord? attendanceRecord;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const SubjectCard({
    super.key,
    required this.subject,
    this.attendanceRecord,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  Future<void> _handleMarkAttendance(String status) async {
    final provider = context.read<AttendanceProvider>();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Use helper for absent to ensure consistency if we add more logic there later
    if (status == 'absent') {
      await provider.markAbsent(widget.subject.id, today);
      if (mounted) {
        // Use custom UI notification
        SnackbarHelper.show(
          context,
          'Marked absent for ${widget.subject.name}',
          icon: LucideIcons.alertCircle,
        );
      }
    } else {
      await provider.markAttendance(widget.subject.id, today, status);
    }

    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Sort days in proper weekday order: Mon, Tue, Wed, Thu, Fri, Sat, Sun
  List<String> _getSortedDays(List<String> days) {
    const dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sortedDays = List<String>.from(days);
    sortedDays.sort((a, b) {
      final indexA = dayOrder.indexOf(a);
      final indexB = dayOrder.indexOf(b);
      // Handle unknown days by putting them at the end
      return (indexA == -1 ? 999 : indexA).compareTo(
        indexB == -1 ? 999 : indexB,
      );
    });
    return sortedDays;
  }

  Color _getStatusColor(AttendanceRecord? record, ColorScheme colorScheme) {
    if (record == null) return colorScheme.onSurfaceVariant;

    if (record.dutyRequested && !record.dutyApproved) {
      return Colors.amber; // Pending/amber
    }

    switch (record.status) {
      case 'present':
        return const Color(0xFF2ECC71); // Success/green
      case 'absent':
        return const Color(0xFFE74C3C); // Destructive/red
      case 'duty-leave':

        // "Approved duty: green badge 'Duty'".
        // I'll change duty-leave to green or a distinct green-ish color.
        // Let's use a different green or same as present?
        // "Duty Leave counts as attendance...".
        // Let's use a nice Teal or similar to distinguish from raw Present but still "Good".
        // Or just stick to prompt: "Approved duty: green badge 'Duty'".
        return const Color(0xFF2ECC71);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData? _getStatusIcon(AttendanceRecord? record) {
    if (record == null) return null;

    if (record.dutyRequested && !record.dutyApproved) {
      return LucideIcons.clock; // Pending icon
    }

    switch (record.status) {
      case 'present':
        return LucideIcons.check;
      case 'absent':
        return LucideIcons.x;
      case 'duty-leave':
        return LucideIcons.briefcase; // Duty icon (Approved)
      default:
        return null;
    }
  }

  String _getStatusLabel(AttendanceRecord? record) {
    if (record == null) return '';

    if (record.dutyRequested && !record.dutyApproved) {
      return 'Requested';
    }

    if (record.status == 'duty-leave') {
      return 'Duty';
    }

    return record.status
        .split('-')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<AttendanceProvider>();
    final attendanceData = provider.getSubjectAttendanceData(widget.subject.id);
    final attendancePercentage = attendanceData.attendancePercentage.round();
    final isAtRisk = attendancePercentage < widget.subject.requiredAttendance;

    final statusColor = _getStatusColor(widget.attendanceRecord, colorScheme);
    final statusIcon = _getStatusIcon(widget.attendanceRecord);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface, // Distinct solid color (Surface)
        borderRadius: BorderRadius.circular(16), // Soft rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Subtle depth
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16), // Rule 1: Padding all(16)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Title Row with optional Edit button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.subject.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onEdit != null)
                      IconButton(
                        icon: Icon(
                          LucideIcons.pencil,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onPressed: widget.onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Edit subject',
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        onPressed: widget.onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Delete subject',
                      ),
                  ],
                ),

                const SizedBox(height: 12), // Rule 5: Title -> 12px gap
                // 2. Weekday Chips
                if (widget.subject.days.isNotEmpty)
                  Wrap(
                    spacing: 8, // Rule 3: SizedBox(width: 8) equivalent
                    runSpacing: 8,
                    children: _getSortedDays(widget.subject.days).map((day) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  // Placeholder
                  const SizedBox.shrink(),

                const SizedBox(height: 16), // Rule 5: Chips -> 16px gap
                // 3. Attendance Label/Percentage Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // Rule 2: Medium weight
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$attendancePercentage%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold, // Rule 4: Bold
                        color: isAtRisk
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFF2ECC71), // Rule 4: Colored
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8), // Rule 5: Label Row -> 8px gap
                // 4. Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    6,
                  ), // Rule 4: Rounded ends
                  child: LinearProgressIndicator(
                    value: attendancePercentage / 100,
                    minHeight: 10, // Rule 4: 10px-12px
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAtRisk
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFF2ECC71),
                    ),
                  ),
                ),

                const SizedBox(height: 16), // Rule 5: Progress Bar -> 16px gap
                // 5. Footer (Target, Status, Semester)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Left: Target & Semester
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Target: ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${widget.subject.requiredAttendance.round()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (widget.subject.endMonth != null &&
                            widget.subject.endMonth!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Until ${widget.subject.endMonth!}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Right: Status (Badge or Buttons)
                    if (widget.attendanceRecord?.status != null &&
                        widget.attendanceRecord!.status != 'duty-leave')
                      PopupMenuButton<String>(
                        onSelected: (newStatus) async {
                          if (newStatus != widget.attendanceRecord!.status) {
                            final today = DateTime.now()
                                .toIso8601String()
                                .split('T')[0];
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            await provider.markAttendance(
                              widget.subject.id,
                              today,
                              newStatus,
                            );
                            if (mounted) {
                              SnackbarHelper.showWithMessenger(
                                scaffoldMessenger,
                                'Changed to ${newStatus == 'present' ? 'Present' : 'Absent'}',
                                icon: newStatus == 'present'
                                    ? LucideIcons.check
                                    : LucideIcons.x,
                              );
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'present',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: const Color(0xFF2ECC71),
                                ),
                                const SizedBox(width: 8),
                                const Text('Present'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'absent',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.x,
                                  size: 16,
                                  color: const Color(0xFFE74C3C),
                                ),
                                const SizedBox(width: 8),
                                const Text('Absent'),
                              ],
                            ),
                          ),
                        ],
                        tooltip: 'Tap to change status',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (statusIcon != null)
                                Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusLabel(widget.attendanceRecord),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevronDown,
                                size: 12,
                                color: statusColor,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (widget.attendanceRecord?.status == 'duty-leave')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (statusIcon != null)
                              Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusLabel(widget.attendanceRecord),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.showActions)
                      Row(
                        children: [
                          _buildActionButton(
                            context,
                            'Present',
                            LucideIcons.check,
                            const Color(0xFF2ECC71),
                            () => _handleMarkAttendance('present'),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            context,
                            'Absent',
                            LucideIcons.x,
                            const Color(0xFFE74C3C),
                            () => _handleMarkAttendance('absent'),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${attendanceData.classesAttended}/${attendanceData.classesHeld}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

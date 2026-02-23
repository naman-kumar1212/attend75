import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/attendance_provider.dart';

import '../widgets/attendance_overview.dart';
import '../widgets/animated_interactions.dart';

import '../utils/ui_constants.dart';
import '../utils/animations.dart';
import '../utils/snackbar_helper.dart';
import '../utils/responsive.dart';
import '../main.dart'; // For MainNavigator tab switching
import '../models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final responsive = context.responsive;

    // Get today's lecture slots (sorted by time) - only those with valid subjects
    final allLectureSlots = provider.getLectureSlotsForDate(today);
    final todaysLectureSlots = allLectureSlots
        .where((slot) => provider.subjects.any((s) => s.id == slot.subjectId))
        .toList();
    final enhancedStats = provider.getAttendanceStats();

    // Use responsive padding - adjusts automatically for mobile vs desktop
    final contentPadding = responsive.contentPaddingWithNav;

    return SingleChildScrollView(
      // Unified Scroll Parent with Physics
      physics: const BouncingScrollPhysics(),
      // Only vertical padding - scrollbar should reach window edge
      padding: EdgeInsets.only(
        top: contentPadding.top,
        bottom: contentPadding.bottom,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.isDesktop ? double.infinity : 1200,
          ),
          // Horizontal padding applied inside the constraint for proper content margins
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: contentPadding.left),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInAnimation(
                  duration: UIConstants.animationNormal,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20), // Generous padding
                    decoration: BoxDecoration(
                      color: colorScheme.surface, // White/Surface
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(
                          alpha: 0.3,
                        ), // Subtle grey border
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.05,
                          ), // Soft diffuse shadow
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side (Expanded)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Icon + "Today"
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.calendar,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight:
                                          FontWeight.w400, // Light weight
                                      color:
                                          colorScheme.onSurfaceVariant, // Grey
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Spacer
                              // Main Date
                              Text(
                                _formatDate(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 24, // Large
                                  fontWeight: FontWeight.bold, // Bold
                                  color: colorScheme.onSurface, // High contrast
                                  height: 1.2,
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12), // Spacer
                              // Sub-Label: Icon + "Classes"
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.bookOpen,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Classes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12), // Min 12px margin from text
                        // Right Side: Briefcase + Count
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Briefcase and Count row (aligned at top)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Icon(
                                    LucideIcons.briefcase,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  todaysLectureSlots.length.toString().padLeft(
                                    2,
                                    '0',
                                  ), // "04" style
                                  style: TextStyle(
                                    fontSize: 40, // Very Large
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme
                                        .primary, // Primary color for emphasis
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: UIConstants.spacing32),

                // Attendance Overview
                FadeInAnimation(
                  duration: UIConstants.animationNormal,
                  delay: const Duration(milliseconds: 100),
                  child: AttendanceOverview(stats: enhancedStats),
                ),
                const SizedBox(height: 32),

                // Today's Classes Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal:
                        4, // Reduced horizontal padding as parent has 16
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      const Padding(
                        padding: EdgeInsets.only(top: 8), // 8px top margin
                        child: Text(
                          "Today's Classes",
                          style: TextStyle(
                            fontSize: 24, // Approx 24-28px
                            fontWeight: FontWeight.w700, // Bold
                          ),
                        ),
                      ),
                      const SizedBox(height: 28), // 28px gap
                      if (todaysLectureSlots.isEmpty) ...[
                        // State A: Empty State
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No classes scheduled for today!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Enjoy your free day 🎉",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.65,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else if (responsive.isDesktop) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final cardWidth =
                                (width - 32) /
                                3; // 3 columns, 16px spacing (2 gaps)
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: todaysLectureSlots.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final slot = entry.value;
                                return SizedBox(
                                  width: cardWidth,
                                  child: _buildLectureSlotItem(
                                    context,
                                    slot,
                                    index,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ] else ...[
                        // State B: Populated State - Show lecture slots with timing
                        Column(
                          children: [
                            for (
                              int index = 0;
                              index < todaysLectureSlots.length;
                              index++
                            ) ...[
                              _buildLectureSlotItem(
                                context,
                                todaysLectureSlots[index],
                                index,
                              ),
                              // Add spacer if not last item
                              if (index < todaysLectureSlots.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Bottom Padding handled by SingleChildScrollView padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build a lecture slot item card with timing
  Widget _buildLectureSlotItem(
    BuildContext context,
    LectureSlot lectureSlot,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Card styling
    final cardColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surface;

    // Data
    final provider = context.watch<AttendanceProvider>();
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Get the subject for this lecture slot - skip if not found
    final subject = provider.subjects
        .where((s) => s.id == lectureSlot.subjectId)
        .firstOrNull;

    // Skip rendering if subject doesn't exist
    if (subject == null) {
      return const SizedBox.shrink();
    }

    // Get attendance status for this specific lecture slot
    final status = provider.getLectureSlotStatus(lectureSlot.id, today);
    final attendanceData = provider.getSubjectAttendanceData(subject.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Header (Subject Name + Time Badge)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lectureSlot.timeRange,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Section B: Duration info + Status
          Row(
            children: [
              // Duration chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${lectureSlot.durationHours}h lecture',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if (status != null && status != AttendanceStatus.dutyLeave)
                PopupMenuButton<String>(
                  onSelected: (newStatus) async {
                    final currentStatus = status == AttendanceStatus.present
                        ? 'present'
                        : 'absent';
                    if (newStatus != currentStatus) {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await context
                          .read<AttendanceProvider>()
                          .markLectureAttendance(
                            lectureSlotId: lectureSlot.id,
                            date: today,
                            status: newStatus,
                          );
                      SnackbarHelper.showWithMessenger(
                        scaffoldMessenger,
                        'Changed to ${newStatus == 'present' ? 'Present' : 'Absent'}',
                        icon: newStatus == 'present'
                            ? LucideIcons.check
                            : LucideIcons.x,
                      );
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
                            color: const Color(0xFF22C55E),
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
                            color: const Color(0xFFEF4444),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(status).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 12,
                          color: _getStatusColor(status),
                        ),
                      ],
                    ),
                  ),
                )
              else if (status == AttendanceStatus.dutyLeave)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          // Section C: Attendance Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subject Attendance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${attendanceData.attendancePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: attendanceData.isAtRisk
                            ? colorScheme.error
                            : const Color(0xFF22C55E),
                      ),
                    ),
                    if (attendanceData.isAtRisk)
                      TextSpan(
                        text: ' (!)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedProgressBar(
            value: attendanceData.attendancePercentage / 100,
            minHeight: 12,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: attendanceData.isAtRisk
                ? colorScheme.error
                : const Color(0xFF22C55E),
            borderRadius: BorderRadius.circular(6),
          ),

          // Animated Shrink Section: Action Buttons
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: status == null
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      // Section D: Action Row (Present / Absent)
                      Row(
                        children: [
                          // Present Button
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              label: 'Present',
                              icon: LucideIcons.check,
                              color: const Color(0xFF22C55E), // Green
                              onTap: () async {
                                try {
                                  await context
                                      .read<AttendanceProvider>()
                                      .markLectureAttendance(
                                        lectureSlotId: lectureSlot.id,
                                        date: today,
                                        status: 'present',
                                      );
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackbarHelper.show(
                                      context,
                                      'Failed to mark attendance. Please try again.',
                                      icon: LucideIcons.alertCircle,
                                    );
                                  }
                                }
                              },
                              isSelected: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Absent Button
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              label: 'Absent',
                              icon: LucideIcons.x,
                              color: const Color(0xFFEF4444), // Red
                              onTap: () async {
                                try {
                                  await context
                                      .read<AttendanceProvider>()
                                      .markLectureAttendance(
                                        lectureSlotId: lectureSlot.id,
                                        date: today,
                                        status: 'absent',
                                      );
                                  if (context.mounted) {
                                    SnackbarHelper.show(
                                      context,
                                      'Absent: ${subject.name}',
                                      icon: LucideIcons.userMinus,
                                      action: SnackBarAction(
                                        label: 'APPLY DUTY LEAVE',
                                        textColor: Colors.amber,
                                        onPressed: () {
                                          MainNavigator.switchToTab(3);
                                        },
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackbarHelper.show(
                                      context,
                                      'Failed to mark attendance. Please try again.',
                                      icon: LucideIcons.alertCircle,
                                    );
                                  }
                                }
                              },
                              isSelected: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF22C55E);
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444);
      case AttendanceStatus.dutyLeave:
        return Colors.orange; // Or any specific Duty Leave color
    }
  }

  String _getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.dutyLeave:
        return 'Duty Leave';
    }
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    // If selected, show solid color; else subtle outlined
    final bgColor = isSelected ? color : color.withValues(alpha: 0.05);
    final borderColor = isSelected ? color : color.withValues(alpha: 0.2);
    final textColor = isSelected ? Colors.white : color;
    final iconColor = isSelected ? Colors.white : color;

    final isDesktop = Responsive.isDesktop(context);

    return ScaleTap(
      onTap: onTap,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        // InkWell inside for ripple
        child: Container(
          height: isDesktop ? 36 : 48, // Reduced height for desktop
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isDesktop ? 16 : 18, color: iconColor),
              SizedBox(width: isDesktop ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Short months for "Oct 24, 2024" format
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

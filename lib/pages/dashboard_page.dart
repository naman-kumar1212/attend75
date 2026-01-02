import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/attendance_provider.dart';
import '../models.dart';
import '../utils/responsive.dart';
import '../utils/theme.dart';
import '../utils/ui_constants.dart';
import '../utils/animations.dart';
import '../utils/attendance_calculator.dart';
import '../widgets/subject_ring_card.dart';

class DashboardPage extends StatefulWidget {
  final String? initialSubjectId;

  /// When true, uses standard padding (for pushed screens with their own AppBar)
  final bool isStandalone;

  const DashboardPage({
    super.key,
    this.initialSubjectId,
    this.isStandalone = false,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? selectedSubjectId; // null means "All Subjects"

  @override
  void initState() {
    super.initState();
    selectedSubjectId = widget.initialSubjectId;
  }

  // Helper method to calculate stats for a single subject
  AttendanceStats _getSubjectStats(
    AttendanceProvider provider,
    String subjectId,
  ) {
    final data = provider.getSubjectAttendanceData(subjectId);

    // Get records for this subject
    final subjectRecords = provider.attendanceRecords
        .where((r) => r.subjectId == subjectId)
        .toList();

    final totalPresent = subjectRecords
        .where((r) => r.status == 'present' || r.status == 'duty-leave')
        .length;
    final totalAbsent = subjectRecords
        .where((r) => r.status == 'absent')
        .length;
    final totalDutyLeave = subjectRecords
        .where((r) => r.status == 'duty-leave')
        .length;

    return AttendanceStats(
      totalPresent: totalPresent,
      totalAbsent: totalAbsent,
      totalDutyLeave: totalDutyLeave,
      totalRecords: subjectRecords.length,
      totalClassesHeld: data.classesHeld,
      totalClassesAttended: data.classesAttended,
      attendancePercentage: data.attendancePercentage,
      physicalAttendancePercentage: data.physicalAttendancePercentage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final responsive = context.responsive;

    // Filter subjects based on selection
    final selectedSubjects =
        (selectedSubjectId == null || selectedSubjectId == 'all')
        ? provider.subjects
        : provider.subjects.where((s) => s.id == selectedSubjectId).toList();

    // Calculate stats based on selected subject(s)
    final stats = (selectedSubjectId == null || selectedSubjectId == 'all')
        ? provider.getAttendanceStats()
        : _getSubjectStats(provider, selectedSubjectId!);

    // Calculate at-risk subjects for selected view
    final atRiskSubjects = selectedSubjects.where((subject) {
      final data = provider.getSubjectAttendanceData(subject.id);
      return data.attendancePercentage < subject.requiredAttendance;
    }).toList();

    return SingleChildScrollView(
      padding: widget.isStandalone
          ? responsive.pagePadding.copyWith(bottom: 24)
          : responsive.contentPaddingWithNav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overview of your attendance performance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Subject Selector Dropdown
              if (provider.subjects.isNotEmpty)
                SizedBox(
                  width: 160,
                  child: PopupMenuButton<String?>(
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    tooltip: 'Select subject to filter',
                    onSelected: (String? value) {
                      setState(() {
                        selectedSubjectId = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String?>(
                          value: 'all',
                          child: Text(
                            'All Subjects',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ...provider.subjects.map((subject) {
                          return PopupMenuItem<String?>(
                            value: subject.id,
                            child: Text(
                              subject.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }),
                      ];
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              (selectedSubjectId == null ||
                                      selectedSubjectId == 'all')
                                  ? 'All Subjects'
                                  : provider.subjects
                                        .firstWhere(
                                          (s) => s.id == selectedSubjectId,
                                          orElse: () => provider.subjects.first,
                                        )
                                        .name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight:
                                        (selectedSubjectId == null ||
                                            selectedSubjectId == 'all')
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronDown, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: responsive.spacing),

          // Stats Cards - Conditional Layout
          (selectedSubjectId == null || selectedSubjectId == 'all')
              ? _buildAggregatedView(
                  context,
                  responsive,
                  stats,
                  atRiskSubjects,
                  selectedSubjects,
                )
              : _buildSingleSubjectView(
                  context,
                  responsive,
                  provider,
                  selectedSubjectId!,
                ),
          SizedBox(height: responsive.spacing),

          // Subject Performance
          if (selectedSubjects.isNotEmpty) ...[
            Text(
              'Subject Performance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: UIConstants.spacing16),
            FadeInAnimation(
              duration: UIConstants.animationNormal,
              delay: Duration(milliseconds: 400),
              child: Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedSubjects.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final subject = selectedSubjects[index];
                    final data = provider.getSubjectAttendanceData(subject.id);
                    final percentage = data.attendancePercentage.round();
                    final isAtRisk = percentage < subject.requiredAttendance;

                    // Calculate attendance advice
                    final advice = calculateAttendanceAdvice(
                      attended: data.classesAttended,
                      totalHeld: data.classesHeld,
                      classesPerWeek: subject.classesPerWeek,
                      threshold: subject.requiredAttendance,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        subject.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (isAtRisk) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'At Risk',
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${data.classesAttended} of ${data.classesHeld} classes attended',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isAtRisk
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).colorScheme.success,
                                  ),
                                ),
                                Text(
                                  'Target: ${subject.requiredAttendance.round()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Theme.of(context).dividerColor,
                          color: isAtRisk
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.success,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 12),
                        // Attendance Advice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                (advice.isAboveThreshold
                                        ? Theme.of(context).colorScheme.success
                                        : Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                advice.isAboveThreshold
                                    ? LucideIcons.checkCircle
                                    : LucideIcons.info,
                                size: 16,
                                color: advice.isAboveThreshold
                                    ? Theme.of(context).colorScheme.success
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  advice.message,
                                  maxLines: 1, // Single line constraint
                                  overflow:
                                      TextOverflow.ellipsis, // Truncate cleanly
                                  style: TextStyle(
                                    fontSize: 11, // Smaller text
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.trendingUp,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Attendance Data Yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by adding your subjects to track attendance',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Build aggregated view (1 large + 2 small rings) for All Subjects
  Widget _buildAggregatedView(
    BuildContext context,
    ResponsiveValues responsive,
    AttendanceStats stats,
    List<Subject> atRiskSubjects,
    List<Subject> selectedSubjects,
  ) {
    // Calculate enhanced metrics
    final atRiskPercentage = selectedSubjects.isNotEmpty
        ? (atRiskSubjects.length / selectedSubjects.length) * 100
        : 0.0;

    final isAboveThreshold = stats.attendancePercentage >= 75;

    return Column(
      children: [
        // Large central ring - Overall Attendance
        SlideInUpAnimation(
          duration: UIConstants.animationSlow,
          delay: Duration(milliseconds: 0),
          child: SubjectRingCard(
            value: stats.attendancePercentage,
            maxValue: 100,
            label: 'Overall Attendance',
            color: isAboveThreshold
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.error,
            subtitle: stats.totalClassesHeld > 0
                ? '${stats.totalClassesAttended}/${stats.totalClassesHeld} classes'
                : 'No classes yet',
            size: 150, // Reduced Main Ring Size
            padding: 20.0,
          ),
        ),

        SizedBox(height: UIConstants.spacing24),

        // Row with 2 smaller rings - Equal Height Enforcement
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ring: Subjects At Risk
              Expanded(
                child: SlideInUpAnimation(
                  duration: UIConstants.animationSlow,
                  delay: Duration(milliseconds: 100),
                  child: SubjectRingCard(
                    value: atRiskPercentage,
                    maxValue: 100,
                    label: 'Subjects At Risk',
                    color: atRiskPercentage > 50
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.warning,
                    subtitle: selectedSubjects.isNotEmpty
                        ? '${atRiskSubjects.length} of ${selectedSubjects.length}'
                        : 'No subjects',
                    size: 85, // Reduced Secondary Ring Size
                    padding: 16.0,
                  ),
                ),
              ),
              SizedBox(width: UIConstants.spacing16),
              // Ring: Physical Attendance
              Expanded(
                child: SlideInUpAnimation(
                  duration: UIConstants.animationSlow,
                  delay: Duration(milliseconds: 200),
                  child: SubjectRingCard(
                    value: stats.physicalAttendancePercentage,
                    maxValue: 100,
                    label: 'Physical Presence',
                    color: Colors.blue,
                    subtitle: '${stats.totalPresent} classes',
                    size: 85, // Reduced Secondary Ring Size
                    padding: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build single subject view with large ring + advice
  Widget _buildSingleSubjectView(
    BuildContext context,
    ResponsiveValues responsive,
    AttendanceProvider provider,
    String subjectId,
  ) {
    final subject = provider.subjects.firstWhere((s) => s.id == subjectId);
    final data = provider.getSubjectAttendanceData(subjectId);
    final advice = calculateAttendanceAdvice(
      attended: data.classesAttended,
      totalHeld: data.classesHeld,
      classesPerWeek: subject.classesPerWeek,
      threshold: subject.requiredAttendance,
    );

    final currentPercent = data.attendancePercentage;
    final isAboveThreshold = currentPercent >= subject.requiredAttendance;

    return Column(
      children: [
        // Large central ring - Attendance %
        SlideInUpAnimation(
          duration: UIConstants.animationSlow,
          delay: Duration(milliseconds: 0),
          child: Column(
            children: [
              SubjectRingCard(
                value: currentPercent,
                maxValue: 100,
                label: 'Effective: ${currentPercent.round()}% (with duty)',
                color: isAboveThreshold
                    ? Theme.of(context).colorScheme.success
                    : Theme.of(context).colorScheme.error,
                subtitle: '${data.classesAttended}/${data.classesHeld} classes',
                size: 150, // Reduced Main Ring Size
                padding: 20.0,
              ),
              const SizedBox(height: 16),
              // Physical Attendance Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Attendance: ${data.physicalAttendancePercentage.round()}% (without duty)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Effective includes approved duty leaves',
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        LucideIcons.info,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: UIConstants.spacing24),

        // Row with 2 smaller rings - Equal Height Enforcement
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SlideInUpAnimation(
                  duration: UIConstants.animationSlow,
                  delay: Duration(milliseconds: 100),
                  child: SubjectRingCard(
                    value: isAboveThreshold
                        ? advice.classesToSkip.toDouble()
                        : 0,
                    maxValue: 10,
                    label: 'Safe to Skip',
                    color: isAboveThreshold
                        ? Theme.of(context).colorScheme.success
                        : Colors.grey,
                    subtitle: 'Classes you can miss',
                    size: 85, // Reduced Secondary Ring Size
                    padding: 16.0,
                    centerTextOverride: isAboveThreshold
                        ? '${advice.classesToSkip}'
                        : '-',
                  ),
                ),
              ),
              SizedBox(width: UIConstants.spacing16),
              Expanded(
                child: SlideInUpAnimation(
                  duration: UIConstants.animationSlow,
                  delay: Duration(milliseconds: 200),
                  child: SubjectRingCard(
                    value: isAboveThreshold
                        ? 0
                        : advice.classesToAttend.toDouble(),
                    maxValue: 10,
                    label: 'To Reach ${subject.requiredAttendance.round()}%',
                    color: isAboveThreshold
                        ? Theme.of(context).colorScheme.success
                        : Theme.of(context).colorScheme.error,
                    showCheckmark: isAboveThreshold,
                    subtitle: 'Classes needed consecutively',
                    size: 85, // Reduced Secondary Ring Size
                    padding: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: UIConstants.spacing24),

        // Advice card
        SlideInUpAnimation(
          duration: UIConstants.animationSlow,
          delay: Duration(milliseconds: 300),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    isAboveThreshold
                        ? LucideIcons.checkCircle2
                        : LucideIcons.alertCircle,
                    color: isAboveThreshold
                        ? Theme.of(context).colorScheme.success
                        : Theme.of(context).colorScheme.warning,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      advice.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

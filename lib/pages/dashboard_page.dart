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
    final isDesktop = responsive.isDesktop;

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
          : isDesktop
          ? responsive.pagePadding
          : responsive.contentPaddingWithNav,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context, provider, isDesktop),
          SizedBox(height: isDesktop ? 16 : responsive.spacing),

          // Stats Cards - Desktop vs Mobile layout
          (selectedSubjectId == null || selectedSubjectId == 'all')
              ? isDesktop
                    ? _buildDesktopAggregatedView(
                        context,
                        stats,
                        atRiskSubjects,
                        selectedSubjects,
                      )
                    : _buildAggregatedView(
                        context,
                        responsive,
                        stats,
                        atRiskSubjects,
                        selectedSubjects,
                      )
              : isDesktop
              ? _buildDesktopSingleSubjectView(
                  context,
                  provider,
                  selectedSubjectId!,
                )
              : _buildSingleSubjectView(
                  context,
                  responsive,
                  provider,
                  selectedSubjectId!,
                ),
          SizedBox(height: isDesktop ? 16 : responsive.spacing),

          // Subject Performance
          if (selectedSubjects.isNotEmpty) ...[
            Text(
              'Subject Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 18 : null,
              ),
            ),
            SizedBox(height: isDesktop ? 12 : UIConstants.spacing16),
            FadeInAnimation(
              duration: UIConstants.animationNormal,
              delay: Duration(milliseconds: 400),
              child: isDesktop
                  ? _buildDesktopSubjectList(
                      context,
                      provider,
                      selectedSubjects,
                    )
                  : _buildMobileSubjectList(
                      context,
                      provider,
                      selectedSubjects,
                    ),
            ),
          ] else
            _buildEmptyState(context, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AttendanceProvider provider,
    bool isDesktop,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDesktop) {
      // Desktop: Plain header matching Manage Subjects and Duty Leave pages
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overview of your attendance performance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (provider.subjects.isNotEmpty)
            _buildSubjectSelector(context, provider, isDesktop),
        ],
      );
    }

    // Mobile: Original header
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
        if (provider.subjects.isNotEmpty)
          _buildSubjectSelector(context, provider, isDesktop),
      ],
    );
  }

  Widget _buildSubjectSelector(
    BuildContext context,
    AttendanceProvider provider,
    bool isDesktop,
  ) {
    return SizedBox(
      width: isDesktop ? 140 : 160,
      child: PopupMenuButton<String?>(
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 10 : 12,
            vertical: isDesktop ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  (selectedSubjectId == null || selectedSubjectId == 'all')
                      ? 'All Subjects'
                      : provider.subjects
                            .firstWhere(
                              (s) => s.id == selectedSubjectId,
                              orElse: () => provider.subjects.first,
                            )
                            .name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 14,
                    fontWeight:
                        (selectedSubjectId == null ||
                            selectedSubjectId == 'all')
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronDown, size: isDesktop ? 14 : 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop: Horizontal compact layout with smaller rings
  Widget _buildDesktopAggregatedView(
    BuildContext context,
    AttendanceStats stats,
    List<Subject> atRiskSubjects,
    List<Subject> selectedSubjects,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final atRiskPercentage = selectedSubjects.isNotEmpty
        ? (atRiskSubjects.length / selectedSubjects.length) * 100
        : 0.0;
    final isAboveThreshold = stats.attendancePercentage >= 75;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Overall Attendance
          Expanded(
            flex: 2,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  // Ring - 90px, stroke 10px
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: stats.attendancePercentage / 100,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: isAboveThreshold
                                ? colorScheme.success
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          '${stats.attendancePercentage.round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text stack
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overall Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${stats.totalClassesAttended} of ${stats.totalClassesHeld} classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 2. At Risk
          Expanded(
            flex: 1,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        if (atRiskSubjects.isNotEmpty)
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: atRiskPercentage / 100,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        Text(
                          atRiskSubjects.isNotEmpty
                              ? '${atRiskPercentage.round()}%'
                              : '0',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: atRiskSubjects.isEmpty
                                ? colorScheme.onSurfaceVariant
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          atRiskSubjects.isEmpty
                              ? 'No Subjects at Risk'
                              : 'At Risk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${atRiskSubjects.length} of ${selectedSubjects.length} subjects',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 3. Physical Presence
          Expanded(
            flex: 1,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: stats.physicalAttendancePercentage / 100,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '${stats.physicalAttendancePercentage.round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Physical Presence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${stats.totalPresent} of ${stats.totalClassesHeld} classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop: Subject list with compact rows (Redesigned per user request)
  Widget _buildDesktopSubjectList(
    BuildContext context,
    AttendanceProvider provider,
    List<Subject> subjects,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildSubjectPerformanceCard(context, subjects[index], provider);
      },
    );
  }

  Widget _buildSubjectPerformanceCard(
    BuildContext context,
    Subject subject,
    AttendanceProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = provider.getSubjectAttendanceData(subject.id);
    final percentage = data.attendancePercentage.round();
    final isAtRisk = percentage < subject.requiredAttendance;

    final advice = calculateAttendanceAdvice(
      attended: data.classesAttended,
      totalHeld: data.classesHeld,
      classesPerWeek: subject.classesPerWeek,
      threshold: subject.requiredAttendance,
    );

    // Color logic
    final statusColor = isAtRisk
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final percentageColor = isAtRisk
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF22C55E); // Brighter
    final cardBgByTheme = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgByTheme,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name + Badge .... Percentage
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAtRisk) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F1515), // Dark red bg
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'At Risk',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B), // Light red text
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: percentageColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Row 2: "X of Y classes attended" .... "Target: 75%"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.classesAttended} of ${data.classesHeld} classes attended',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Target: ${subject.requiredAttendance.round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 3: Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 16),

          // Row 4: Advice Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2538), // Dark purple/grey per image
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.info,
                  color: Color(0xFFA855F7), // Purple icon
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    advice.message,
                    style: const TextStyle(
                      color: Colors.white, // Text usually white on dark box
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop: Single subject view - compact horizontal
  Widget _buildDesktopSingleSubjectView(
    BuildContext context,
    AttendanceProvider provider,
    String subjectId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Subject Attendance
          Expanded(
            flex: 2,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  // Ring - 90px, stroke 10px
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: currentPercent / 100,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: isAboveThreshold
                                ? colorScheme.success
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          '${currentPercent.round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text stack
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data.classesAttended} of ${data.classesHeld} classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 2. Safe to Skip / Need to Attend
          Expanded(
            flex: 1,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: isAboveThreshold
                                ? colorScheme.success
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        Text(
                          isAboveThreshold
                              ? '${advice.classesToSkip}'
                              : '${advice.classesToAttend}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isAboveThreshold ? 'Safe to Skip' : 'Need to Attend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'consecutive classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 3. Physical Presence
          Expanded(
            flex: 1,
            child: _DesktopStatCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 10,
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: data.physicalAttendancePercentage / 100,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          '${data.physicalAttendancePercentage.round()}%',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Physical Presence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data.classesAttended} of ${data.classesHeld} classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state matching Duty Leave / Manage Subjects style
  Widget _buildEmptyState(BuildContext context, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.barChart3,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Attendance Data Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your subjects to track attendance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: Subject list (original)
  Widget _buildMobileSubjectList(
    BuildContext context,
    AttendanceProvider provider,
    List<Subject> subjects,
  ) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final data = provider.getSubjectAttendanceData(subject.id);
          final percentage = data.attendancePercentage.round();
          final isAtRisk = percentage < subject.requiredAttendance;

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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'At Risk',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface,
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
    );
  }

  // Build aggregated view (1 large + 2 small rings) for All Subjects - MOBILE
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
            size: 150,
            padding: 20.0,
          ),
        ),

        SizedBox(height: UIConstants.spacing24),

        // Row with 2 smaller rings
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    size: 85,
                    padding: 16.0,
                  ),
                ),
              ),
              SizedBox(width: UIConstants.spacing16),
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
                    size: 85,
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

  // Build single subject view with large ring + advice - MOBILE
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
                size: 150,
                padding: 20.0,
              ),
              const SizedBox(height: 16),
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
                    size: 85,
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
                    size: 85,
                    padding: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: UIConstants.spacing24),

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

/// Desktop stat card (static, no hover effect)
class _DesktopStatCard extends StatelessWidget {
  final Widget child;

  const _DesktopStatCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

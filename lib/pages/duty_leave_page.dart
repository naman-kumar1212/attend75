import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/attendance_provider.dart';
import '../models.dart';
import '../utils/responsive.dart';
import '../utils/snackbar_helper.dart';

class DutyLeavePage extends StatefulWidget {
  const DutyLeavePage({super.key});

  @override
  State<DutyLeavePage> createState() => _DutyLeavePageState();
}

class _DutyLeavePageState extends State<DutyLeavePage> {
  // Dialog to convert absent to duty leave
  void _showConvertToDutyDialog(AttendanceRecord record, Subject subject) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Convert to Duty Leave',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subject: ${subject.name}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Date: ${_formatDate(record.date)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Event / Reason',
                  hintText: 'e.g., Sports Meet, Medical Camp',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Duty leave counts as attendance only after approval.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final provider = context.read<AttendanceProvider>();
                provider
                    .requestDutyLeave(
                      record.subjectId,
                      record.date,
                      reasonController.text.trim(),
                    )
                    .then((_) {
                      provider.approveDutyLeave(record.subjectId, record.date);
                    });

                Navigator.pop(context);
                SnackbarHelper.showSuccess(
                  context,
                  'Marked as Approved Duty Leave',
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Duty Leave'),
          ),
        ],
      ),
    );
  }

  void _undoDutyLeave(AttendanceRecord record) {
    final provider = context.read<AttendanceProvider>();
    provider.cancelDutyRequest(record.subjectId, record.date);

    SnackbarHelper.show(
      context,
      'Duty Leave removed',
      icon: LucideIcons.trash2,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (record.dutyReason != null) {
            provider
                .requestDutyLeave(
                  record.subjectId,
                  record.date,
                  record.dutyReason!,
                )
                .then(
                  (_) =>
                      provider.approveDutyLeave(record.subjectId, record.date),
                );
          }
        },
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
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
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final responsive = context.responsive;
    final attendanceRecords = provider.attendanceRecords;
    final subjects = provider.subjects;
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Approved Duty Leaves
    final approvedRecords = attendanceRecords
        .where((r) => r.status == 'duty-leave' || r.dutyApproved)
        .toList();
    approvedRecords.sort((a, b) => b.date.compareTo(a.date));

    // 2. Missed Lectures (Absent)
    final missedRecords = provider.listAllAbsentRecordsAcrossSubjects();
    missedRecords.sort((a, b) => b.date.compareTo(a.date));

    final bool hasNoData = approvedRecords.isEmpty && missedRecords.isEmpty;

    // Desktop: Use simple pagePadding (no extra top space since AppBar is not transparent)
    // Mobile: Use contentPaddingWithNav (accounts for transparent glass app bar)
    final padding = responsive.isDesktop
        ? responsive.pagePadding.copyWith(bottom: 24)
        : responsive.contentPaddingWithNav;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Text(
              'Duty Leave',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your duty leaves and missed lectures',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Empty State
            if (hasNoData)
              _buildFullEmptyState(context)
            else ...[
              // SECTION 1: Approved Duty Leaves
              _buildSectionHeader(
                context,
                'Approved Duty Leaves',
                LucideIcons.checkCircle,
                const Color(0xFF2ECC71),
                approvedRecords.length,
              ),
              const SizedBox(height: 12),
              if (approvedRecords.isEmpty)
                _buildEmptyState(context, 'No approved duty leaves yet.')
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Calculate card width: aim for 3-4 cards per row
                    final cardCount = width > 1200
                        ? 4
                        : (width > 800 ? 3 : (width > 500 ? 2 : 1));
                    final spacing = 16.0;
                    final cardWidth =
                        (width - (spacing * (cardCount - 1))) / cardCount;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: approvedRecords.map((record) {
                        final subject = subjects.firstWhere(
                          (s) => s.id == record.subjectId,
                          orElse: () =>
                              Subject(id: '', name: 'Unknown', daysOfWeek: []),
                        );
                        return SizedBox(
                          width: cardWidth,
                          child: _buildApprovedCard(context, subject, record),
                        );
                      }).toList(),
                    );
                  },
                ),

              const SizedBox(height: 28),

              // SECTION 2: Lectures Missed
              _buildSectionHeader(
                context,
                'Lectures Missed',
                LucideIcons.alertCircle,
                colorScheme.error,
                missedRecords.length,
              ),
              const SizedBox(height: 12),
              if (missedRecords.isEmpty)
                _buildEmptyState(
                  context,
                  'No missed lectures. Mark attendance from Home to see them here.',
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    // Calculate card width: aim for 3-4 cards per row
                    final cardCount = width > 1200
                        ? 4
                        : (width > 800 ? 3 : (width > 500 ? 2 : 1));
                    final spacing = 16.0;
                    final cardWidth =
                        (width - (spacing * (cardCount - 1))) / cardCount;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: missedRecords.map((record) {
                        final subject = subjects.firstWhere(
                          (s) => s.id == record.subjectId,
                          orElse: () =>
                              Subject(id: '', name: 'Unknown', daysOfWeek: []),
                        );
                        return SizedBox(
                          width: cardWidth,
                          child: _buildMissedCard(context, subject, record),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    int count,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullEmptyState(BuildContext context) {
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
        children: [
          Icon(
            LucideIcons.briefcase,
            size: 48,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Duty Leaves Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you mark absent on the Home page, those lectures will appear here. You can then convert them to Duty Leave.',
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

  Widget _buildEmptyState(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
    );
  }

  Widget _buildApprovedCard(
    BuildContext context,
    Subject subject,
    AttendanceRecord record,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surface;

    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Subject Name + Status Badge
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
                    _buildBadge('Duty Leave', const Color(0xFF2ECC71)),
                  ],
                ),
                const SizedBox(height: 8),
                // Date row
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(record.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (record.dutyReason != null &&
                    record.dutyReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.fileText,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.dutyReason!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              LucideIcons.undo2,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _undoDutyLeave(record),
            tooltip: 'Remove Duty Leave',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedCard(
    BuildContext context,
    Subject subject,
    AttendanceRecord record,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surface;

    return Container(
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Name + Status Badge
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
              _buildBadge('Absent', colorScheme.error),
            ],
          ),
          const SizedBox(height: 8),
          // Date row
          Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(record.date),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          // Convert button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _showConvertToDutyDialog(record, subject),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.arrowRightLeft,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Convert to Duty Leave',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

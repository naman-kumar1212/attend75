import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models.dart';
import '../utils/ui_constants.dart';
import 'animated_interactions.dart';

class AttendanceOverview extends StatelessWidget {
  final AttendanceStats stats;

  const AttendanceOverview({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAtRisk = stats.attendancePercentage < 75;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attendance Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Vertical Stack of Cards
        _OverviewCard(
          icon: LucideIcons.target,
          label: 'Overall Attendance',
          value: '${stats.attendancePercentage.round()}%',
          color: isAtRisk ? const Color(0xFFE74C3C) : const Color(0xFF2ECC71),
          showProgress: true,
          progress: stats.attendancePercentage / 100,
        ),
        const SizedBox(height: 16),
        _OverviewCard(
          icon: LucideIcons.bookOpen,
          label: 'Classes Attended',
          value: '${stats.totalClassesAttended} / ${stats.totalClassesHeld}',
          color: colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _OverviewCard(
          icon: LucideIcons.trendingUp,
          label: 'Total Classes',
          value: '${stats.totalClassesHeld}',
          color: colorScheme.tertiary, // Using tertiary for variety/neutrality
        ),
      ],
    );
  }
}

// Keeping original _OverviewCard for Mobile/Tablet compatibility
class _OverviewCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showProgress;
  final double? progress;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showProgress = false,
    this.progress,
  });

  @override
  State<_OverviewCard> createState() => _OverviewCardState();
}

class _OverviewCardState extends State<_OverviewCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(UIConstants.radiusLarge),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, size: 20, color: widget.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.showProgress && widget.progress != null) ...[
                const SizedBox(height: 8),
                AnimatedProgressBar(
                  value: widget.progress!,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

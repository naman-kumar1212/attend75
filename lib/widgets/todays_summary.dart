import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/ui_constants.dart';
import '../utils/responsive.dart';

class TodaysSummary extends StatelessWidget {
  final String date;
  final int totalClasses;

  const TodaysSummary({
    super.key,
    required this.date,
    required this.totalClasses,
  });

  String _formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsive = context.responsive;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(UIConstants.spacing24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(UIConstants.spacing16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(UIConstants.radiusMedium),
              ),
              child: Icon(
                LucideIcons.calendarDays,
                color: colorScheme.onPrimary,
                size: responsive.value(
                  mobile: UIConstants.iconLarge,
                  tablet: UIConstants.iconXLarge,
                  desktop: UIConstants.iconXLarge,
                ),
              ),
            ),
            SizedBox(width: UIConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: UIConstants.spacing4),
                  Text(
                    totalClasses == 0
                        ? 'No classes scheduled'
                        : totalClasses == 1
                        ? '1 class today'
                        : '$totalClasses classes today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

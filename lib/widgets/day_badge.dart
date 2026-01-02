import 'package:flutter/material.dart';
import '../utils/ui_constants.dart';

/// Day badge widget for displaying day abbreviations (Mon, Tue, Wed, etc.)
/// Used in subject cards to show which days a subject has classes
class DayBadge extends StatelessWidget {
  final String dayAbbreviation;
  final bool isActive;
  final Color? activeColor;

  const DayBadge({
    super.key,
    required this.dayAbbreviation,
    this.isActive = true,
    this.activeColor,
  });

  /// Factory constructors for each day of week
  factory DayBadge.monday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Mon',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.tuesday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Tue',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.wednesday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Wed',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.thursday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Thu',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.friday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Fri',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.saturday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Sat',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  factory DayBadge.sunday({bool isActive = true, Color? activeColor}) {
    return DayBadge(
      dayAbbreviation: 'Sun',
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  /// Create day badge from day number (1 = Monday, 7 = Sunday)
  factory DayBadge.fromDayNumber(
    int dayNumber, {
    bool isActive = true,
    Color? activeColor,
  }) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return DayBadge(
      dayAbbreviation: days[(dayNumber - 1) % 7],
      isActive: isActive,
      activeColor: activeColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = activeColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? effectiveColor.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusSmall),
        border: Border.all(
          color: isActive
              ? effectiveColor.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        dayAbbreviation,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? effectiveColor : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Helper to create day badges from a list of day names
class DayBadgeList extends StatelessWidget {
  final List<String> days;
  final Color? activeColor;

  const DayBadgeList({super.key, required this.days, this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((day) {
        return DayBadge(
          dayAbbreviation: day,
          isActive: true,
          activeColor: activeColor,
        );
      }).toList(),
    );
  }
}

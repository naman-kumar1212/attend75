import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../utils/responsive.dart';

/// A mutable lecture slot for editing in the UI.
/// This is used during editing and converted to LectureSlot on save.
class EditableLectureSlot {
  String id;
  TimeOfDay startTime;
  int durationHours;

  EditableLectureSlot({
    required this.id,
    required this.startTime,
    this.durationHours = 1,
  });

  /// Create from existing LectureSlot
  factory EditableLectureSlot.fromLectureSlot(LectureSlot slot) {
    return EditableLectureSlot(
      id: slot.id,
      startTime: slot.startTimeOfDay,
      durationHours: slot.durationHours,
    );
  }

  /// Convert to LectureSlot for saving
  LectureSlot toLectureSlot({
    required String subjectId,
    required Weekday weekday,
  }) {
    return LectureSlot.fromTimeOfDay(
      id: id,
      subjectId: subjectId,
      weekday: weekday,
      startTimeOfDay: startTime,
      durationHours: durationHours,
    );
  }

  /// Get end time based on duration
  TimeOfDay get endTime =>
      TimeOfDay(hour: startTime.hour + durationHours, minute: startTime.minute);

  /// Check if overlaps with another slot
  bool overlaps(EditableLectureSlot other) {
    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = thisStart + (durationHours * 60);
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = otherStart + (other.durationHours * 60);

    return thisStart < otherEnd && otherStart < thisEnd;
  }

  /// Format time for display with AM/PM
  /// Format time for display with smart AM/PM (e.g. "9:00 - 10:00 AM")
  String get formattedTime {
    final startPeriod = startTime.period == DayPeriod.am ? 'AM' : 'PM';
    final endPeriod = endTime.period == DayPeriod.am ? 'AM' : 'PM';

    // If same period, show "9:00 - 10:00 AM"
    if (startPeriod == endPeriod) {
      final start = _formatTimeNoPeriod(startTime);
      final end = _formatTimeAmPm(endTime);
      return '$start - $end';
    }

    // Different periods, show full: "11:00 AM - 1:00 PM"
    final startFormatted = _formatTimeAmPm(startTime);
    final endFormatted = _formatTimeAmPm(endTime);
    return '$startFormatted - $endFormatted';
  }

  String _formatTimeNoPeriod(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Short format for small screens with AM/PM (compact range)
  String get shortFormattedTime {
    return '${_formatTimeCompact(startTime)}-${_formatTimeCompact(endTime)}';
  }

  /// Helper to format time in 12-hour AM/PM format
  String _formatTimeAmPm(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Compact format without minutes if on the hour
  String _formatTimeCompact(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'A' : 'P';
    if (time.minute == 0) {
      return '$hour$period';
    }
    return '$hour:${time.minute.toString().padLeft(2, '0')}$period';
  }
}

/// Weekly schedule state for editing
class WeeklyScheduleState {
  final Map<Weekday, List<EditableLectureSlot>> schedule;

  WeeklyScheduleState() : schedule = {for (var day in Weekday.values) day: []};

  /// Initialize from existing lecture slots
  factory WeeklyScheduleState.fromLectureSlots(List<LectureSlot> slots) {
    final state = WeeklyScheduleState();
    for (final slot in slots) {
      final weekday = slot.weekday;
      state.schedule[weekday]!.add(EditableLectureSlot.fromLectureSlot(slot));
    }
    // Sort slots by time for each day
    for (final day in state.schedule.keys) {
      state.schedule[day]!.sort(
        (a, b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(
          b.startTime.hour * 60 + b.startTime.minute,
        ),
      );
    }
    return state;
  }

  /// Get total lecture count
  int get totalLectures =>
      schedule.values.fold(0, (sum, slots) => sum + slots.length);

  /// Get total hours
  int get totalHours => schedule.values.fold(
    0,
    (sum, slots) => sum + slots.fold(0, (s, slot) => s + slot.durationHours),
  );

  /// Convert to list of LectureSlots for saving
  List<LectureSlot> toLectureSlots(String subjectId) {
    final slots = <LectureSlot>[];
    for (final entry in schedule.entries) {
      for (final editableSlot in entry.value) {
        slots.add(
          editableSlot.toLectureSlot(subjectId: subjectId, weekday: entry.key),
        );
      }
    }
    return slots;
  }

  /// Validate schedule - returns error message or null if valid
  String? validate() {
    if (totalLectures == 0) {
      return 'At least one lecture is required';
    }

    // Check for overlaps within each day
    for (final entry in schedule.entries) {
      final slots = entry.value;
      for (int i = 0; i < slots.length; i++) {
        for (int j = i + 1; j < slots.length; j++) {
          if (slots[i].overlaps(slots[j])) {
            return 'Overlapping lectures on ${entry.key.fullName}';
          }
        }
      }
    }

    return null;
  }
}

/// Main widget for editing weekly lecture schedule.
/// Displays an expandable list of weekdays with lecture slots.
class WeeklyScheduleEditor extends StatefulWidget {
  final WeeklyScheduleState scheduleState;
  final VoidCallback onChanged;

  const WeeklyScheduleEditor({
    super.key,
    required this.scheduleState,
    required this.onChanged,
  });

  @override
  State<WeeklyScheduleEditor> createState() => _WeeklyScheduleEditorState();
}

class _WeeklyScheduleEditorState extends State<WeeklyScheduleEditor> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = Responsive.isSmallPhone(context);

    final headerFontSize = Responsive.phoneValue<double>(
      context,
      small: 14,
      medium: 15,
      large: 16,
    );
    final badgeFontSize = Responsive.phoneValue<double>(
      context,
      small: 10,
      medium: 11,
      large: 12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(vertical: isSmall ? 6 : 8),
          child: Row(
            children: [
              Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 8 : 10,
                  vertical: isSmall ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
                ),
                child: Text(
                  '${widget.scheduleState.totalLectures} lec • ${widget.scheduleState.totalHours}h',
                  style: TextStyle(
                    fontSize: badgeFontSize,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Day tiles (Monday to Sunday order)
        ...[
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
          Weekday.saturday,
          Weekday.sunday,
        ].map(
          (weekday) => DayScheduleTile(
            weekday: weekday,
            slots: widget.scheduleState.schedule[weekday]!,
            onAddSlot: () => _addSlot(weekday),
            onRemoveSlot: (index) => _removeSlot(weekday, index),
            onSlotChanged: (index, slot) => _updateSlot(weekday, index, slot),
          ),
        ),
      ],
    );
  }

  void _addSlot(Weekday weekday) {
    // Find a non-overlapping time slot
    TimeOfDay newStartTime = const TimeOfDay(hour: 9, minute: 0);
    final existingSlots = widget.scheduleState.schedule[weekday]!;

    if (existingSlots.isNotEmpty) {
      // Find the latest end time and add 1 hour gap
      int latestEnd = 0;
      for (final slot in existingSlots) {
        final end = slot.endTime.hour * 60 + slot.endTime.minute;
        if (end > latestEnd) latestEnd = end;
      }
      newStartTime = TimeOfDay(hour: (latestEnd ~/ 60) + 1, minute: 0);
      if (newStartTime.hour > 22) {
        newStartTime = const TimeOfDay(hour: 8, minute: 0);
      }
    }

    final newSlot = EditableLectureSlot(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      startTime: newStartTime,
      durationHours: 1,
    );

    setState(() {
      existingSlots.add(newSlot);
      _sortSlots(weekday);
    });
    widget.onChanged();
  }

  void _removeSlot(Weekday weekday, int index) {
    setState(() {
      widget.scheduleState.schedule[weekday]!.removeAt(index);
    });
    widget.onChanged();
  }

  void _updateSlot(Weekday weekday, int index, EditableLectureSlot slot) {
    setState(() {
      widget.scheduleState.schedule[weekday]![index] = slot;
      _sortSlots(weekday);
    });
    widget.onChanged();
  }

  void _sortSlots(Weekday weekday) {
    widget.scheduleState.schedule[weekday]!.sort(
      (a, b) => (a.startTime.hour * 60 + a.startTime.minute).compareTo(
        b.startTime.hour * 60 + b.startTime.minute,
      ),
    );
  }
}

/// A single day's schedule tile with expandable lecture slots.
class DayScheduleTile extends StatelessWidget {
  final Weekday weekday;
  final List<EditableLectureSlot> slots;
  final VoidCallback onAddSlot;
  final void Function(int index) onRemoveSlot;
  final void Function(int index, EditableLectureSlot slot) onSlotChanged;

  const DayScheduleTile({
    super.key,
    required this.weekday,
    required this.slots,
    required this.onAddSlot,
    required this.onRemoveSlot,
    required this.onSlotChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSlots = slots.isNotEmpty;
    final isSmall = Responsive.isSmallPhone(context);

    final dayBoxSize = Responsive.phoneValue<double>(
      context,
      small: 34,
      medium: 38,
      large: 40,
    );
    final titleFontSize = Responsive.phoneValue<double>(
      context,
      small: 13,
      medium: 14,
      large: 15,
    );
    final dayFontSize = Responsive.phoneValue<double>(
      context,
      small: 10,
      medium: 11,
      large: 12,
    );

    return Card(
      margin: EdgeInsets.only(bottom: isSmall ? 6 : 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
        side: BorderSide(
          color: hasSlots
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: 0,
          ),
          leading: Container(
            width: dayBoxSize,
            height: dayBoxSize,
            decoration: BoxDecoration(
              color: hasSlots
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
            ),
            child: Center(
              child: Text(
                weekday.shortName,
                style: TextStyle(
                  fontSize: dayFontSize,
                  fontWeight: FontWeight.w600,
                  color: hasSlots
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          title: Text(
            weekday.fullName,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSlots)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 6 : 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
                  ),
                  child: Text(
                    '${slots.length}',
                    style: TextStyle(
                      fontSize: isSmall ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              SizedBox(width: isSmall ? 4 : 8),
              Icon(Icons.expand_more, size: isSmall ? 20 : 24),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isSmall ? 12 : 16,
                0,
                isSmall ? 12 : 16,
                isSmall ? 12 : 16,
              ),
              child: Column(
                children: [
                  // Existing slots
                  ...slots.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
                      child: LectureSlotTile(
                        slot: entry.value,
                        onChanged: (updatedSlot) =>
                            onSlotChanged(entry.key, updatedSlot),
                        onDelete: () => onRemoveSlot(entry.key),
                      ),
                    ),
                  ),

                  // Add lecture button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddSlot,
                      icon: Icon(Icons.add, size: isSmall ? 16 : 18),
                      label: Text(
                        'Add Lecture',
                        style: TextStyle(fontSize: isSmall ? 12 : 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 8 : 10,
                        ),
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          style: BorderStyle.solid,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
                        ),
                      ),
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

/// A single lecture slot tile with time picker and duration dropdown.
class LectureSlotTile extends StatelessWidget {
  final EditableLectureSlot slot;
  final void Function(EditableLectureSlot) onChanged;
  final VoidCallback onDelete;

  const LectureSlotTile({
    super.key,
    required this.slot,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmall = Responsive.isSmallPhone(context);

    final tilePadding = Responsive.phoneValue<double>(
      context,
      small: 8,
      medium: 10,
      large: 12,
    );
    final timeFontSize = Responsive.phoneValue<double>(
      context,
      small: 12,
      medium: 13,
      large: 13, // reduced max size slightly
    );

    return Container(
      padding: EdgeInsets.all(tilePadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(isSmall ? 8 : 10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Time picker button
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 8 : 10, // Reduced from 12
                  vertical: isSmall ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: isSmall ? 14 : 16, // Reduced from 18
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: isSmall ? 4 : 6), // Reduced from 8
                    Expanded(
                      child: Text(
                        isSmall ? slot.shortFormattedTime : slot.formattedTime,
                        style: TextStyle(
                          fontSize: timeFontSize,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: isSmall ? 6 : 8),

          // Duration dropdown
          SizedBox(
            width: isSmall ? 65 : 80, // Reduced from 70/85
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 4 : 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: slot.durationHours,
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: isSmall ? 16 : 18,
                  ),
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13,
                    color: colorScheme.onSurface,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 1,
                      child: Text(isSmall ? '1h' : '1 hr'),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(isSmall ? '2h' : '2 hrs'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onChanged(
                        EditableLectureSlot(
                          id: slot.id,
                          startTime: slot.startTime,
                          durationHours: value,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),

          SizedBox(width: isSmall ? 4 : 8),

          // Delete button
          IconButton(
            onPressed: onDelete,
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            constraints: BoxConstraints(
              minWidth: isSmall ? 32 : 36, // Reduced slightly
              minHeight: isSmall ? 32 : 36,
            ),
            icon: Icon(
              Icons.delete_outline,
              size: isSmall ? 18 : 20,
              color: colorScheme.error,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.errorContainer.withValues(
                alpha: 0.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(
        EditableLectureSlot(
          id: slot.id,
          startTime: picked,
          durationHours: slot.durationHours,
        ),
      );
    }
  }
}

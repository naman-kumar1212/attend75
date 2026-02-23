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

        // Day tiles (Monday to Saturday)
        ...[
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
          Weekday.saturday,
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
class DayScheduleTile extends StatefulWidget {
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
  State<DayScheduleTile> createState() => _DayScheduleTileState();
}

class _DayScheduleTileState extends State<DayScheduleTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSlots = widget.slots.isNotEmpty;
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
      child: Column(
        children: [
          // Header Row (Clickable)
          InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(isSmall ? 10 : 12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 16,
                vertical: 12, // Default visual density padding equivalent
              ),
              child: Row(
                children: [
                  // Leading: Day Box
                  Container(
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
                        widget.weekday.shortName,
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
                  SizedBox(width: isSmall ? 12 : 16), // Standard list tile gap
                  // Title
                  Expanded(
                    child: Text(
                      widget.weekday.fullName,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // Trailing: Count Badge + Expand Icon
                  if (hasSlots) ...[
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
                        '${widget.slots.length}',
                        style: TextStyle(
                          fontSize: isSmall ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    SizedBox(width: isSmall ? 4 : 8),
                  ],
                  RotationTransition(
                    turns: _iconTurns,
                    child: Icon(
                      Icons.expand_more,
                      size: isSmall ? 20 : 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Body (Expandable)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmall ? 12 : 16,
                      0,
                      isSmall ? 12 : 16,
                      isSmall ? 12 : 16,
                    ),
                    child: Column(
                      children: [
                        // Existing slots
                        ...widget.slots.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
                            child: LectureSlotTile(
                              slot: entry.value,
                              onChanged: (updatedSlot) =>
                                  widget.onSlotChanged(entry.key, updatedSlot),
                              onDelete: () => widget.onRemoveSlot(entry.key),
                            ),
                          ),
                        ),

                        // Add lecture + Delete button row (60-40 split)
                        Row(
                          children: [
                            // Add Lecture button (60%)
                            Expanded(
                              flex: 6,
                              child: OutlinedButton.icon(
                                onPressed: widget.onAddSlot,
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
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    style: BorderStyle.solid,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      isSmall ? 8 : 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (hasSlots) ...[
                              SizedBox(width: isSmall ? 6 : 8),
                              // Delete button (40%)
                              Expanded(
                                flex: 4,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Remove the last slot
                                    widget.onRemoveSlot(
                                      widget.slots.length - 1,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: isSmall ? 16 : 18,
                                  ),
                                  label: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: isSmall ? 12 : 14,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: isSmall ? 8 : 10,
                                    ),
                                    foregroundColor: colorScheme.error,
                                    side: BorderSide(
                                      color: colorScheme.error.withValues(
                                        alpha: 0.5,
                                      ),
                                      style: BorderStyle.solid,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isSmall ? 8 : 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
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

    // Fixed height for all row elements ensuring alignment
    const double componentHeight = 42.0;

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
      large: 14,
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
          // Time picker button (flex 3)
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
              child: Container(
                height: componentHeight,
                padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
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
                      size: isSmall ? 14 : 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: isSmall ? 4 : 8),
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

          // Duration dropdown (flex 2)
          Expanded(
            flex: 2,
            child: Container(
              height: componentHeight,
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: slot.durationHours,
                  isExpanded: true,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: isSmall ? 18 : 20,
                  ),
                  style: TextStyle(
                    fontSize: isSmall ? 12 : 13,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
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
                    DropdownMenuItem(
                      value: 3,
                      child: Text(isSmall ? '3h' : '3 hrs'),
                    ),
                    DropdownMenuItem(
                      value: 4,
                      child: Text(isSmall ? '4h' : '4 hrs'),
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
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: slot.startTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            ),
          ),
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

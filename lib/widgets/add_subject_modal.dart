import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers/attendance_provider.dart';
import '../utils/snackbar_helper.dart';
import '../utils/responsive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'weekly_schedule_editor.dart';

class AddSubjectModal extends StatefulWidget {
  /// Optional subject for edit mode. If null, creates new subject.
  final Subject? subject;

  const AddSubjectModal({super.key, this.subject});

  @override
  State<AddSubjectModal> createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends State<AddSubjectModal> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _heldController = TextEditingController(text: '0');
  final _attendedController = TextEditingController(text: '0');

  // State
  double _requiredAttendance = 75.0;
  late WeeklyScheduleState _scheduleState = WeeklyScheduleState();
  DateTime? _startMonth;
  DateTime? _endMonth;
  bool _isLoading = false;

  // Edit mode check
  bool get _isEditMode => widget.subject != null;

  // Get theme-aware colors
  Color _getBgColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  Color _getSurfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  Color _getErrorColor(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  // Responsive helpers
  double _getPadding(BuildContext context) =>
      Responsive.phoneValue(context, small: 16, medium: 20, large: 24);

  double _getSpacing(BuildContext context) =>
      Responsive.phoneValue(context, small: 16, medium: 20, large: 24);

  double _getHeaderFontSize(BuildContext context) =>
      Responsive.phoneValue(context, small: 20, medium: 22, large: 24);

  double _getSubtitleFontSize(BuildContext context) =>
      Responsive.phoneValue(context, small: 12, medium: 13, large: 14);

  double _getLabelFontSize(BuildContext context) =>
      Responsive.phoneValue(context, small: 12, medium: 13, large: 14);

  double _getInputFontSize(BuildContext context) =>
      Responsive.phoneValue(context, small: 14, medium: 15, large: 16);

  double _getButtonPadding(BuildContext context) =>
      Responsive.phoneValue(context, small: 12, medium: 14, large: 16);

  @override
  void initState() {
    super.initState();

    // Pre-fill data if editing
    if (_isEditMode) {
      final subject = widget.subject!;
      _nameController.text = subject.name;
      _heldController.text = subject.classesHeld.toString();
      _attendedController.text = subject.classesAttended.toString();
      _requiredAttendance = subject.requiredAttendance;

      // Load existing lecture slots for this subject
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<AttendanceProvider>();
        final existingSlots = provider.getLectureSlotsForSubject(subject.id);
        setState(() {
          _scheduleState = WeeklyScheduleState.fromLectureSlots(existingSlots);
        });
      });
      // Initialize with empty schedule (will be populated above)
      _scheduleState = WeeklyScheduleState();

      // Parse month strings back to DateTime
      if (subject.startMonth != null && subject.startMonth!.isNotEmpty) {
        try {
          _startMonth = DateFormat('yyyy-MM').parse(subject.startMonth!);
        } catch (_) {}
      }
      if (subject.endMonth != null && subject.endMonth!.isNotEmpty) {
        try {
          _endMonth = DateFormat('yyyy-MM').parse(subject.endMonth!);
        } catch (_) {}
      }
    } else {
      // New subject: start with empty schedule
      _scheduleState = WeeklyScheduleState();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heldController.dispose();
    _attendedController.dispose();
    super.dispose();
  }

  Future<void> _saveSubject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate weekly schedule
    final scheduleError = _scheduleState.validate();
    if (scheduleError != null) {
      SnackbarHelper.show(
        context,
        scheduleError,
        icon: LucideIcons.calendarX,
        backgroundColor: _getErrorColor(context),
      );
      return;
    }

    final held = int.tryParse(_heldController.text) ?? 0;
    final attended = int.tryParse(_attendedController.text) ?? 0;

    if (attended > held) {
      SnackbarHelper.show(
        context,
        'Attended classes cannot exceed held classes',
        icon: LucideIcons.alertTriangle,
        backgroundColor: _getErrorColor(context),
      );
      return;
    }

    // Validate month range
    if (_startMonth != null && _endMonth != null) {
      if (_endMonth!.isBefore(_startMonth!)) {
        SnackbarHelper.show(
          context,
          'End month cannot be before start month',
          icon: LucideIcons.calendarOff,
          backgroundColor: _getErrorColor(context),
        );
        return;
      }
    }

    // Get days that have lectures
    final daysWithLectures = _scheduleState.schedule.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key.value)
        .toList();

    final subject = Subject(
      id: _isEditMode
          ? widget.subject!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      initialHoursHeld: held,
      initialHoursAttended: attended,
      daysOfWeek: daysWithLectures,
      requiredAttendance: _requiredAttendance,
      startMonth: _startMonth != null
          ? DateFormat('yyyy-MM').format(_startMonth!)
          : null,
      endMonth: _endMonth != null
          ? DateFormat('yyyy-MM').format(_endMonth!)
          : null,
    );

    // Convert schedule to lecture slots
    final lectureSlots = _scheduleState.toLectureSlots(subject.id);

    final provider = context.read<AttendanceProvider>();

    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await provider.updateSubject(subject);
        // Update lecture slots
        await provider.updateLectureSlots(subject.id, lectureSlots);
      } else {
        await provider.addSubjectWithSlots(subject, lectureSlots);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          'Failed to save subject: ${e.toString().replaceAll('Exception: ', '')}',
          icon: LucideIcons.alertTriangle,
          backgroundColor: _getErrorColor(context),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMonth(bool isStart) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_startMonth ?? now)
        : (_endMonth ?? _startMonth ?? now);

    final firstDate = DateTime(now.year - 1, 1);
    final lastDate = DateTime(now.year + 5, 12);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: isStart ? 'Select Start Month' : 'Select End Month',
      locale: const Locale('en', 'GB'),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startMonth = DateTime(picked.year, picked.month);
        } else {
          _endMonth = DateTime(picked.year, picked.month);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBgColor(context);
    final padding = _getPadding(context);
    final spacing = _getSpacing(context);
    final isSmall = Responsive.isSmallPhone(context);

    // Responsive inset padding
    final insetPadding = EdgeInsets.symmetric(
      horizontal: Responsive.phoneValue(
        context,
        small: 12,
        medium: 16,
        large: 20,
      ),
      vertical: Responsive.phoneValue(
        context,
        small: 24,
        medium: 32,
        large: 40,
      ),
    );

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
      ),
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.phoneValue(
            context,
            small: 400,
            medium: 450,
            large: 500,
          ),
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: spacing),
                _buildSubjectNameField(),
                SizedBox(height: spacing),
                _buildStatsRow(),
                SizedBox(height: spacing),
                _buildAttendanceSlider(),
                SizedBox(height: spacing),
                _buildDaysSelector(),
                SizedBox(height: spacing),
                _buildMonthRangeSelector(),
                SizedBox(height: spacing + 8),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final headerSize = _getHeaderFontSize(context);
    final subtitleSize = _getSubtitleFontSize(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode ? 'Edit Subject' : 'Add New Subject',
                style: TextStyle(
                  fontSize: headerSize,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditMode
                    ? 'Update subject details and class schedule.'
                    : 'Add a new subject to track attendance.',
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x),
          color: colorScheme.onSurfaceVariant,
          // Remove default padding to align nicely with edge
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: _getLabelFontSize(context),
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {String? hint}) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = _getSurfaceColor(context);
    final theme = Theme.of(context);
    final errorColor = _getErrorColor(context);
    final isSmall = Responsive.isSmallPhone(context);

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurfaceVariant,
        fontSize: _getInputFontSize(context),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 14,
        vertical: isSmall ? 8 : 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        borderSide: BorderSide(color: accentColor, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
    );
  }

  Widget _buildSubjectNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Subject Name'),
        TextFormField(
          controller: _nameController,
          style: TextStyle(fontSize: _getInputFontSize(context)),
          decoration: _inputDecoration(context, hint: 'e.g. Mathematics'),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final isSmall = Responsive.isSmallPhone(context);
    final gap = isSmall ? 10.0 : 16.0;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Classes Held'),
              TextFormField(
                controller: _heldController,
                style: TextStyle(fontSize: _getInputFontSize(context)),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(context),
                validator: (value) =>
                    int.tryParse(value ?? '') == null ? 'Invalid' : null,
              ),
            ],
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Attended'),
              TextFormField(
                controller: _attendedController,
                style: TextStyle(fontSize: _getInputFontSize(context)),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(context),
                validator: (value) =>
                    int.tryParse(value ?? '') == null ? 'Invalid' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSlider() {
    final accentColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = _getSurfaceColor(context);
    final labelSize = _getLabelFontSize(context);
    final isSmall = Responsive.isSmallPhone(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Required Attendance',
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${_requiredAttendance.round()}%',
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: surfaceColor,
            thumbColor: accentColor,
            overlayColor: accentColor.withValues(alpha: 0.2),
            trackHeight: isSmall ? 3 : 4,
          ),
          child: Slider(
            value: _requiredAttendance,
            min: 50,
            max: 100,
            divisions: 20,
            label: '${_requiredAttendance.round()}%',
            onChanged: (value) => setState(() => _requiredAttendance = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '50%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
              Text(
                '75%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isSmall ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    return WeeklyScheduleEditor(
      scheduleState: _scheduleState,
      onChanged: () => setState(() {}),
    );
  }

  Widget _buildMonthRangeSelector() {
    final isSmall = Responsive.isSmallPhone(context);
    final gap = isSmall ? 10.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Subject Duration'),
        Row(
          children: [
            Expanded(
              child: _buildMonthButton(
                label: 'Start',
                value: _startMonth,
                onTap: () => _selectMonth(true),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildMonthButton(
                label: 'End',
                value: _endMonth,
                onTap: () => _selectMonth(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Auto-removes after end month.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: Responsive.phoneValue(
              context,
              small: 10,
              medium: 11,
              large: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthButton({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final surfaceColor = _getSurfaceColor(context);
    final accentColor = Theme.of(context).colorScheme.primary;
    final isSmall = Responsive.isSmallPhone(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
          border: Border.all(
            color: value != null
                ? accentColor.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.calendar,
              size: isSmall ? 16 : 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: isSmall ? 6 : 8),
            Expanded(
              child: Text(
                value != null ? DateFormat('MMM yy').format(value) : label,
                style: TextStyle(
                  color: value != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: isSmall ? 12 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final accentColor = Theme.of(context).colorScheme.primary;
    final buttonPadding = _getButtonPadding(context);
    final isSmall = Responsive.isSmallPhone(context);
    final buttonRadius = isSmall ? 8.0 : 10.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: isSmall ? 13 : 14),
            ),
          ),
        ),
        SizedBox(width: isSmall ? 10 : 16),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : _saveSubject,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              padding: EdgeInsets.symmetric(vertical: buttonPadding),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonRadius),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: isSmall ? 18 : 20,
                    width: isSmall ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditMode ? 'Save' : 'Add',
                    style: TextStyle(fontSize: isSmall ? 13 : 14),
                  ),
          ),
        ),
      ],
    );
  }
}

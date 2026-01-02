import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/settings_provider.dart';
import '../../services/permissions_service.dart';

class AttendanceSettingsWidget extends StatefulWidget {
  const AttendanceSettingsWidget({super.key});

  @override
  State<AttendanceSettingsWidget> createState() =>
      _AttendanceSettingsWidgetState();
}

class _AttendanceSettingsWidgetState extends State<AttendanceSettingsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _resetAnimationController;
  late Animation<double> _resetAnimation;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _resetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _resetAnimation = CurvedAnimation(
      parent: _resetAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _resetAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleReset(SettingsProvider settingsProvider) async {
    setState(() {
      _isResetting = true;
    });

    // Start pulse animation
    await _resetAnimationController.forward();

    // Reset settings
    await settingsProvider.resetSettings();

    // Reverse animation
    await _resetAnimationController.reverse();

    setState(() {
      _isResetting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final settings = settingsProvider.settings;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Preferences',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your attendance tracking preferences and thresholds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Default Required Attendance
            _buildSliderSection(
              context,
              title: 'Default Required Attendance',
              value: settings.defaultRequiredAttendance,
              min: 50,
              max: 100,
              divisions: 50, // (100-50)/1 = 50 steps
              label: '${settings.defaultRequiredAttendance.toInt()}%',
              description:
                  'This will be the default attendance requirement for new subjects',
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settings.copyWith(defaultRequiredAttendance: value),
                );
              },
            ),

            const SizedBox(height: 24),
            Text(
              'Alert Thresholds',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Warning Threshold
            _buildSliderSection(
              context,
              title: 'Show warning at',
              value: settings.showWarningAt,
              min: 70,
              max: 100,
              divisions: 30,
              label: '${settings.showWarningAt.toInt()}%',
              badgeColor: Colors.amber,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settings.copyWith(showWarningAt: value),
                );
              },
            ),

            const SizedBox(height: 16),

            // Critical Threshold
            _buildSliderSection(
              context,
              title: 'Show critical at',
              value: settings.showCriticalAt,
              min: 50,
              max: settings.showWarningAt,
              divisions: (settings.showWarningAt - 50).toInt(),
              label: '${settings.showCriticalAt.toInt()}%',
              badgeColor: Colors.red,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settings.copyWith(showCriticalAt: value),
                );
              },
            ),

            const SizedBox(height: 24),

            // Toggles
            _buildSwitchTile(
              context,
              title: 'Include Duty Leaves in Attendance',
              subtitle:
                  'Count duty leaves as present when calculating percentages',
              value: settings.includeDutyLeaves,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settings.copyWith(includeDutyLeaves: value),
                );
              },
            ),

            _buildSwitchTile(
              context,
              title: 'Auto-mark Weekends',
              subtitle:
                  'Automatically skip weekend days in attendance tracking',
              value: settings.autoMarkWeekends,
              onChanged: (value) {
                settingsProvider.updateSettings(
                  settings.copyWith(autoMarkWeekends: value),
                );
              },
            ),

            // Daily Reminders with permission request
            _buildNotificationToggle(context, settingsProvider, settings),

            if (settings.notificationsEnabled) ...[
              const SizedBox(height: 16),
              _buildTimePicker(
                context,
                time: settings.reminderTime,
                onChanged: (newTime) {
                  settingsProvider.updateSettings(
                    settings.copyWith(reminderTime: newTime),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Save Status & Reset with smooth transition
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Row(
                children: [
                  // Animated save status - Flexible to take available space
                  // ClipRect ensures text doesn't overflow into button area
                  Flexible(
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                        child: KeyedSubtree(
                          key: ValueKey<SaveStatus>(
                            settingsProvider.saveStatus,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildSaveStatus(
                              context,
                              settingsProvider.saveStatus,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Reset button - fixed size, stays on right
                  AnimatedBuilder(
                    animation: _resetAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 - (_resetAnimation.value * 0.05),
                        child: Opacity(
                          opacity: _isResetting ? 0.7 : 1.0,
                          child: OutlinedButton.icon(
                            onPressed: _isResetting
                                ? null
                                : () => _handleReset(settingsProvider),
                            icon: AnimatedRotation(
                              turns: _isResetting ? -1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: const Icon(
                                LucideIcons.rotateCcw,
                                size: 16,
                              ),
                            ),
                            label: Text(
                              _isResetting ? 'Resetting...' : 'Reset',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface,
                              side: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    String? description,
    Color? badgeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? Theme.of(context).colorScheme.secondary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (badgeColor ?? Theme.of(context).colorScheme.secondary)
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: badgeColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : 1,
            label: label,
            onChanged: onChanged,
          ),
        ),
        if (description != null)
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String time,
    required ValueChanged<String> onChanged,
  }) {
    // Parse time string "HH:MM"
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);

    return Row(
      children: [
        Text(
          'Daily Reminder Time',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: timeOfDay,
            );
            if (picked != null) {
              // Format back to HH:MM
              final h = picked.hour.toString().padLeft(2, '0');
              final m = picked.minute.toString().padLeft(2, '0');
              onChanged('$h:$m');
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              timeOfDay.format(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveStatus(BuildContext context, SaveStatus status) {
    switch (status) {
      case SaveStatus.saving:
        return const Text(
          'Saving...',
          style: TextStyle(color: Colors.blue, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        );
      case SaveStatus.saved:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.check, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Saved',
                style: const TextStyle(color: Colors.green, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case SaveStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Save failed',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case SaveStatus.idle:
        return const SizedBox.shrink();
    }
  }

  /// Daily Reminders toggle with notification permission request (system dialog only)
  Widget _buildNotificationToggle(
    BuildContext context,
    SettingsProvider settingsProvider,
    dynamic settings,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminders',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  "Get notified about today's classes and attendance status",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: settings.notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Request permission (system dialog only)
                final granted = await PermissionsService()
                    .requestNotificationPermission();
                if (!granted) {
                  // Permission denied - don't enable the setting
                  return;
                }
              }
              // Update the setting
              settingsProvider.updateSettings(
                settings.copyWith(notificationsEnabled: value),
              );
            },
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

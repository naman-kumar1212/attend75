import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/permissions_service.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/responsive.dart';

class DataManagement extends StatefulWidget {
  const DataManagement({super.key});

  @override
  State<DataManagement> createState() => _DataManagementState();
}

class _DataManagementState extends State<DataManagement> {
  bool _isImporting = false;
  String? _importError;
  bool _importSuccess = false;

  Future<void> _exportData(AttendanceProvider provider) async {
    // Request permission silently (system dialog only)
    final hasPermission = await PermissionsService().requestFilePermission();
    if (!hasPermission) return;

    try {
      final data = provider.exportData();
      data['version'] = "1.0";

      final String jsonString = jsonEncode(data);
      final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
      final fileName =
          'attendance-data-${DateFormat('dd-MM-yyyy').format(DateTime.now())}.json';

      await _saveFile(bytes, fileName, 'json');
    } catch (e) {
      // Silent failure - no snackbar
      debugPrint('Export failed: $e');
    }
  }

  Future<void> _exportToCSV(AttendanceProvider provider) async {
    // Request permission silently (system dialog only)
    final hasPermission = await PermissionsService().requestFilePermission();
    if (!hasPermission) return;

    try {
      final subjects = provider.subjects;
      final attendanceRecords = provider.attendanceRecords;

      final List<List<String>> csvData = [
        [
          'Date',
          'Subject',
          'Status',
          'Attendance %',
          'Classes Held',
          'Classes Attended',
        ],
      ];

      for (var subject in subjects) {
        final subjectRecords = attendanceRecords
            .where((r) => r.subjectId == subject.id)
            .toList();
        final attendanceData = provider.getSubjectAttendanceData(subject.id);
        final percentage = attendanceData.attendancePercentage.round();

        if (subjectRecords.isNotEmpty) {
          for (var record in subjectRecords) {
            csvData.add([
              DateFormat('dd-MM-yyyy').format(record.dateTime),
              subject.name,
              record.status,
              '$percentage%',
              attendanceData.classesHeld.toString(),
              attendanceData.classesAttended.toString(),
            ]);
          }
        } else {
          csvData.add([
            '',
            subject.name,
            'No records',
            '$percentage%',
            attendanceData.classesHeld.toString(),
            attendanceData.classesAttended.toString(),
          ]);
        }
      }

      final String csvContent = csvData.map((row) => row.join(',')).join('\n');
      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent));
      final fileName =
          'attendance-report-${DateFormat('dd-MM-yyyy').format(DateTime.now())}.csv';

      await _saveFile(bytes, fileName, 'csv');
    } catch (e) {
      // Silent failure - no snackbar
      debugPrint('CSV export failed: $e');
    }
  }

  /// Platform-appropriate file saving using bytes
  Future<void> _saveFile(
    Uint8List bytes,
    String fileName,
    String extension,
  ) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // Mobile: Use file picker with bytes parameter
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );

      if (outputPath != null && mounted) {
        SnackbarHelper.showSuccess(context, 'Saved to $outputPath');
      }
    } else {
      // Desktop: Use file picker to get path, then write file
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (outputPath != null) {
        final file = File(outputPath);
        await file.writeAsBytes(bytes);
        if (mounted) {
          SnackbarHelper.showSuccess(context, 'Saved to $outputPath');
        }
      }
    }
  }

  Future<void> _importData(AttendanceProvider provider) async {
    // Request permission silently (system dialog only)
    final hasPermission = await PermissionsService().requestFilePermission();
    if (!hasPermission) return;

    setState(() {
      _isImporting = true;
      _importError = null;
      _importSuccess = false;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        if (data['version'] != null && data['version'] != "1.0") {
          debugPrint('Data version mismatch. Attempting to import anyway.');
        }

        await provider.importData(data);

        setState(() {
          _importSuccess = true;
        });
      }
    } catch (e) {
      setState(() {
        _importError = e.toString();
      });
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Widget _buildDeleteItem(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colorScheme.error),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Future<void> _clearAllData(AttendanceProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.alertTriangle,
                        size: 32,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete All Data?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Column(
                  children: [
                    Text(
                      'This action will permanently delete:',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Items list
                    _buildDeleteItem(context, LucideIcons.book, 'All subjects'),
                    const SizedBox(height: 8),
                    _buildDeleteItem(
                      context,
                      LucideIcons.calendar,
                      'Attendance records',
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem(
                      context,
                      LucideIcons.settings,
                      'App settings',
                    ),
                    const SizedBox(height: 20),
                    // Warning box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Export your data first if you want to keep a backup.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface,
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Delete All'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await provider.clearAllData();
      if (mounted) {
        SnackbarHelper.show(
          context,
          'All data cleared',
          icon: LucideIcons.trash2,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider to rebuild when data changes
    final provider = Provider.of<AttendanceProvider>(context);
    final isDesktop = context.responsive.isDesktop;

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
              'Data Management',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Export, import, and manage your attendance data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Export Section
            Text(
              'Export Data',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // Use vertical layout for narrow screens (< 320dp available width)
                final isNarrow = constraints.maxWidth < 320;
                final buttonPadding = EdgeInsets.symmetric(
                  vertical: isDesktop ? 20 : 14,
                  horizontal: isNarrow ? 12 : 16,
                );

                Widget buildExportButton({
                  required VoidCallback onPressed,
                  required String label,
                }) {
                  return OutlinedButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(LucideIcons.download, size: 18),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).dividerColor),
                      padding: buttonPadding,
                    ),
                  );
                }

                if (isNarrow) {
                  // Vertical stack for narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildExportButton(
                        onPressed: () => _exportData(provider),
                        label: 'Export as JSON',
                      ),
                      const SizedBox(height: 8),
                      buildExportButton(
                        onPressed: () => _exportToCSV(provider),
                        label: 'Export as CSV',
                      ),
                    ],
                  );
                }

                // Horizontal row for wider screens
                return Row(
                  children: [
                    Expanded(
                      child: buildExportButton(
                        onPressed: () => _exportData(provider),
                        label: 'Export as JSON',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildExportButton(
                        onPressed: () => _exportToCSV(provider),
                        label: 'Export as CSV',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'JSON format preserves all data. CSV format is Excel-compatible.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 24),

            // Import Section
            Text(
              'Import Data',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : () => _importData(provider),
              icon: const Icon(LucideIcons.upload, size: 16),
              label: const Text('Import from JSON'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).dividerColor),
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            if (_isImporting)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Importing data...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_importSuccess)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  '✅ Data imported successfully!',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
            if (_importError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '❌ $_importError',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Import a previously exported JSON file to restore your data.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 32),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 24),

            // Danger Zone
            Text(
              'Danger Zone',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _clearAllData(provider),
              icon: const Icon(LucideIcons.trash2, size: 16),
              label: const Text('Delete All Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                padding: EdgeInsets.symmetric(vertical: isDesktop ? 20 : 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

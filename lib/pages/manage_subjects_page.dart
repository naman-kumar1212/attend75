import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/attendance_provider.dart';
import '../models.dart';
import '../widgets/subject_card.dart';
import '../widgets/add_subject_modal.dart';
import '../utils/responsive.dart';
import '../utils/snackbar_helper.dart';
import 'dashboard_page.dart';

class ManageSubjectsPage extends StatefulWidget {
  const ManageSubjectsPage({super.key});

  @override
  State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  String _searchQuery = '';

  List<Subject> _getFilteredSubjects(List<Subject> subjects) {
    if (_searchQuery.isEmpty) return subjects;
    final query = _searchQuery.toLowerCase();
    return subjects.where((s) {
      return s.name.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddSubjectDialog() {
    showDialog(context: context, builder: (context) => const AddSubjectModal());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final responsive = context.responsive;
    final allSubjects = provider.subjects;
    final filteredSubjects = _getFilteredSubjects(allSubjects);
    final activeCount = allSubjects.length;

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
            // Header
            Text(
              'Manage Subjects',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Add and configure your subjects',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // "Add Subject" Button - Centered, substantial width
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 1.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddSubjectDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: responsive.isDesktop ? 15 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 1,
                    ),
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: const Text(
                      'Add Subject',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search subjects...',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: responsive.isDesktop ? 15 : 10,
                  horizontal: 14,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Stats Line
            Row(
              children: [
                Text(
                  'Total: ${allSubjects.length} subjects',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Active: $activeCount',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Subjects List - Using Column since we're in SingleChildScrollView
            if (filteredSubjects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.searchX,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        provider.subjects.isEmpty
                            ? 'No subjects added yet'
                            : 'No subjects found',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                      if (provider.subjects.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button above to add your first subject',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else if (responsive.isDesktop)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 210, // Fixed height to accommodate content
                ),
                itemCount: filteredSubjects.length,
                itemBuilder: (context, i) {
                  return SubjectCard(
                    subject: filteredSubjects[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: Text(filteredSubjects[i].name),
                            ),
                            body: DashboardPage(
                              initialSubjectId: filteredSubjects[i].id,
                              isStandalone: true,
                            ),
                          ),
                        ),
                      );
                    },
                    onEdit: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            AddSubjectModal(subject: filteredSubjects[i]),
                      );
                    },
                    onDelete: () {
                      final subject = filteredSubjects[i];
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete Subject'),
                          content: Text(
                            'Are you sure you want to delete "${subject.name}"? This will remove all attendance records for this subject.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                Navigator.pop(dialogContext);
                                await provider.deleteSubject(subject.id);
                                SnackbarHelper.showWithMessenger(
                                  scaffoldMessenger,
                                  '${subject.name} deleted',
                                  icon: LucideIcons.trash2,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    showActions: false,
                  );
                },
              )
            else
              Column(
                children: [
                  for (int i = 0; i < filteredSubjects.length; i++) ...[
                    SubjectCard(
                      subject: filteredSubjects[i],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(filteredSubjects[i].name),
                              ),
                              body: DashboardPage(
                                initialSubjectId: filteredSubjects[i].id,
                                isStandalone: true,
                              ),
                            ),
                          ),
                        );
                      },
                      onEdit: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              AddSubjectModal(subject: filteredSubjects[i]),
                        );
                      },
                      onDelete: () {
                        final subject = filteredSubjects[i];
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Subject'),
                            content: Text(
                              'Are you sure you want to delete "${subject.name}"? This will remove all attendance records for this subject.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final scaffoldMessenger =
                                      ScaffoldMessenger.of(context);
                                  Navigator.pop(dialogContext);
                                  await provider.deleteSubject(subject.id);
                                  SnackbarHelper.showWithMessenger(
                                    scaffoldMessenger,
                                    '${subject.name} deleted',
                                    icon: LucideIcons.trash2,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.error,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      showActions: false,
                    ),
                    if (i < filteredSubjects.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

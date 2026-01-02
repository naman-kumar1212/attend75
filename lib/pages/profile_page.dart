import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

import '../widgets/avatar_picker.dart';
import '../utils/snackbar_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedSemester;

  double _targetAttendance = 75.0;
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isInitializing = true;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize only once, then react to profile changes
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializeProfile();
    } else {
      // Re-populate if profile data changed (e.g., after profile update)
      _syncFromProvider();
    }
  }

  /// Initialize profile data - waits for profile to be loaded
  Future<void> _initializeProfile() async {
    final authProvider = context.read<AuthProvider>();
    debugPrint('ProfilePage: Initializing profile...');

    // Ensure profile is fully loaded before populating
    await authProvider.ensureProfileLoaded();
    debugPrint('ProfilePage: Profile loaded, syncing to UI...');

    if (mounted) {
      _syncFromProvider();
      setState(() => _isInitializing = false);
    }
  }

  /// Sync text controllers from provider data
  void _syncFromProvider() {
    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.profile;

    debugPrint('ProfilePage._syncFromProvider: profile=$profile');

    if (profile != null) {
      _firstNameController.text = profile['first_name']?.toString() ?? '';
      _lastNameController.text = profile['last_name']?.toString() ?? '';
      _emailController.text =
          profile['email']?.toString() ?? authProvider.email;
      _phoneController.text = profile['phone']?.toString() ?? '';

      final sem = profile['semester'];
      if (sem != null) {
        _selectedSemester = int.tryParse(sem.toString());
      } else {
        _selectedSemester = null;
      }
      _targetAttendance =
          (profile['target_attendance'] as num?)?.toDouble() ?? 75.0;
      _avatarUrl = profile['avatar_url']?.toString();

      debugPrint(
        'ProfilePage: Synced - firstName=${_firstNameController.text}, lastName=${_lastNameController.text}, email=${_emailController.text}',
      );
    } else {
      // Fallback to user metadata
      _firstNameController.text = authProvider.firstName;
      _lastNameController.text = authProvider.lastName;
      _emailController.text = authProvider.email;
      debugPrint(
        'ProfilePage: Using fallback - firstName=${authProvider.firstName}, lastName=${authProvider.lastName}',
      );
    }

    // Force UI update
    if (mounted) setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    debugPrint('ProfilePage: Saving profile...');

    final authProvider = context.read<AuthProvider>();
    final updatedProfile = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'semester': _selectedSemester,
      'target_attendance': _targetAttendance,
    };

    debugPrint('ProfilePage: Updating with data: $updatedProfile');

    try {
      final success = await authProvider.updateProfile(updatedProfile);

      debugPrint('ProfilePage: Save result: $success');

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          _syncFromProvider(); // Refresh local state from provider
          SnackbarHelper.showSuccess(context, 'Profile updated successfully!');
        } else {
          SnackbarHelper.showError(context, 'Failed to update profile');
        }
      }
    } catch (e) {
      debugPrint('ProfilePage: Save error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, 'Error saving profile: $e');
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        SnackbarHelper.show(
          context,
          'Signed out successfully',
          icon: LucideIcons.logOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _getInitials() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading skeleton while initializing
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 32),
                      _buildPersonalDetailsSection(),
                      const SizedBox(height: 24),
                      _buildAcademicDetailsSection(),
                      const SizedBox(height: 32),
                      _buildActionsSection(),
                      const SizedBox(height: 24),
                      _buildFooterSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        AvatarPicker(
          avatarUrl: _avatarUrl,
          initials: _getInitials(),
          size: 100,
          onAvatarSelected: (path) async {
            setState(() {
              _avatarUrl = path.isEmpty ? null : path;
            });

            // IMMEDIATE PERSISTENCE
            // Update global state immediately as per user requirement
            if (path.isNotEmpty) {
              final authProvider = context.read<AuthProvider>();

              // Upload and update avatar (this handles Storage upload)
              final url = await authProvider.updateAvatar(File(path));

              // Optional: Show quick feedback
              if (mounted) {
                if (url != null) {
                  SnackbarHelper.showSuccess(context, 'Avatar updated');
                } else {
                  SnackbarHelper.showError(context, 'Failed to update avatar');
                }
              }
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          '${context.watch<AuthProvider>().firstName} ${context.watch<AuthProvider>().lastName}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value != null && value.trim().length < 2
                    ? 'Min 2 chars'
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => value != null && value.trim().length < 2
                    ? 'Min 2 chars'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          readOnly: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(LucideIcons.mail, size: 18),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number (Optional)',
            prefixIcon: Icon(LucideIcons.phone, size: 20),
            isDense: true,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildAcademicDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Preferences',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: _selectedSemester,
          decoration: const InputDecoration(
            labelText: 'Semester (Optional)',
            prefixIcon: Icon(LucideIcons.bookOpen, size: 20),
            isDense: true,
            helperText: 'Displayed on your dashboard',
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('None')),
            ...List.generate(8, (index) {
              final val = index + 1;
              return DropdownMenuItem<int?>(
                value: val,
                child: Text(val.toString()),
              );
            }),
          ],
          onChanged: (value) => setState(() => _selectedSemester = value),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Target Attendance',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _targetAttendance >= 75
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_targetAttendance.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _targetAttendance >= 75 ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: _targetAttendance,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: (value) => setState(() => _targetAttendance = value),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveProfile,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(LucideIcons.save, size: 18),
          label: Text(_isSaving ? 'Saving Changes...' : 'Save Profile'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: _signOut,
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    if (profile == null) return const SizedBox.shrink();

    final createdAt = profile['created_at'] != null
        ? DateTime.tryParse(profile['created_at'])
        : null;
    final userId =
        profile['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A';

    return Column(
      children: [
        const Divider(indent: 48, endIndent: 48),
        const SizedBox(height: 16),
        if (createdAt != null)
          Text(
            'Member since ${DateFormat('dd-MM-yyyy').format(createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'ID: $userId',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

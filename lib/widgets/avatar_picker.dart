import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/permissions_service.dart';

class AvatarPicker extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final Function(String) onAvatarSelected;
  final double size;

  const AvatarPicker({
    super.key,
    this.avatarUrl,
    required this.initials,
    required this.onAvatarSelected,
    this.size = 80,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final permissionsService = PermissionsService();

    // Request permission (system dialog only)
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await permissionsService.requestCameraPermission();
    } else {
      hasPermission = await permissionsService.requestPhotoPermission();
    }

    if (!hasPermission) {
      // Silent failure - no snackbar
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        onAvatarSelected(pickedFile.path);
      }
    } catch (e) {
      // Silent failure
      debugPrint('Failed to pick image: $e');
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(context, ImageSource.gallery);
                },
              ),
              if (avatarUrl != null)
                ListTile(
                  leading: const Icon(LucideIcons.trash2),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    onAvatarSelected('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Stack(
        children: [
          // Avatar Circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              image: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? DecorationImage(
                      image: avatarUrl!.startsWith('http')
                          ? NetworkImage(avatarUrl!)
                          : FileImage(File(avatarUrl!)) as ImageProvider,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null || avatarUrl!.isEmpty
                ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          // Camera Icon Button
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                LucideIcons.camera,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing user profiles in Supabase.
/// Handles profile CRUD operations and avatar uploads.
class ProfileService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get the current user's profile.
  /// Returns null only if user is not authenticated.
  Future<Map<String, dynamic>?> getProfile() async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get Profile Error: $e');
      return null;
    }
  }

  /// Get profile or create one if it doesn't exist.
  /// This is the PRIMARY method to use after signup/login.
  /// Ensures profile data is NEVER null for authenticated users.
  Future<Map<String, dynamic>?> getOrCreateProfile() async {
    final userId = SupabaseService.userId;
    final currentUser = SupabaseService.client.auth.currentUser;
    if (userId == null || currentUser == null) return null;

    try {
      // First, try to fetch existing profile
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) {
        // Check if profile needs backfill (empty names but metadata has them)
        final existingFirstName = existing['first_name']?.toString() ?? '';
        final existingLastName = existing['last_name']?.toString() ?? '';
        final existingAvatar = existing['avatar_url']?.toString();

        if (existingFirstName.isEmpty ||
            existingLastName.isEmpty ||
            existingAvatar == null) {
          // Try to get names from metadata
          final userMeta = currentUser.userMetadata;
          String metaFirstName = userMeta?['first_name']?.toString() ?? '';
          String metaLastName = userMeta?['last_name']?.toString() ?? '';

          // Try splitting full_name if individual names are missing
          if (metaFirstName.isEmpty && metaLastName.isEmpty) {
            final fullName = userMeta?['full_name'] ?? userMeta?['name'] ?? '';
            if (fullName != null && fullName.toString().isNotEmpty) {
              final parts = fullName.toString().split(' ');
              if (parts.isNotEmpty) {
                metaFirstName = parts.first;
                if (parts.length > 1) {
                  metaLastName = parts.sublist(1).join(' ');
                }
              }
            }
          }

          // Get avatar from metadata
          final metaAvatar =
              userMeta?['avatar_url']?.toString() ??
              userMeta?['picture']?.toString();

          // Update DB if metadata has better data
          final Map<String, dynamic> updates = {};
          if (existingFirstName.isEmpty && metaFirstName.isNotEmpty) {
            updates['first_name'] = metaFirstName;
          }
          if (existingLastName.isEmpty && metaLastName.isNotEmpty) {
            updates['last_name'] = metaLastName;
          }
          if (existingAvatar == null && metaAvatar != null) {
            updates['avatar_url'] = metaAvatar;
          }

          if (updates.isNotEmpty) {
            debugPrint('ProfileService: Backfilling profile with: $updates');
            updates['updated_at'] = DateTime.now().toIso8601String();
            await _client.from('profiles').update(updates).eq('id', userId);

            // Return updated profile
            final updated = await _client
                .from('profiles')
                .select()
                .eq('id', userId)
                .maybeSingle();
            return updated ?? existing;
          }
        }

        return existing;
      }

      // Profile doesn't exist - create it from auth metadata
      debugPrint('Profile not found, creating from auth metadata...');

      final userMeta = currentUser.userMetadata;
      final email = currentUser.email ?? '';

      // Extract name - handle both separate fields and full name
      String firstName = userMeta?['first_name'] ?? '';
      String lastName = userMeta?['last_name'] ?? '';

      if (firstName.isEmpty && lastName.isEmpty) {
        final fullName = userMeta?['full_name'] ?? userMeta?['name'] ?? '';
        if (fullName.isNotEmpty) {
          final parts = fullName.toString().split(' ');
          if (parts.isNotEmpty) {
            firstName = parts.first;
            if (parts.length > 1) {
              lastName = parts.sublist(1).join(' ');
            }
          }
        }
      }

      // Extract avatar URL - Google often uses 'picture' or 'avatar_url'
      final avatarUrl = userMeta?['avatar_url'] ?? userMeta?['picture'];

      final profileData = {
        'id': userId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'avatar_url': avatarUrl,
        'target_attendance': 75.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Upsert to handle race conditions with database trigger
      await _client.from('profiles').upsert(profileData, onConflict: 'id');

      // Fetch the newly created profile
      final created = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      debugPrint('Profile created successfully: $created');
      return created ?? profileData;
    } catch (e) {
      debugPrint('Get Or Create Profile Error: $e');

      // Fallback: return minimal profile from auth data
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser != null) {
        return {
          'id': userId,
          'email': currentUser.email ?? '',
          'first_name': currentUser.userMetadata?['first_name'] ?? '',
          'last_name': currentUser.userMetadata?['last_name'] ?? '',
          'target_attendance': 75.0,
        };
      }
      return null;
    }
  }

  /// Update the current user's profile.
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    final userId = SupabaseService.userId;
    if (userId == null) return false;

    try {
      // Add updated_at timestamp
      data['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('profiles').upsert({
        'id': userId,
        ...data,
      }, onConflict: 'id');
      return true;
    } catch (e) {
      debugPrint('Update Profile Error: $e');
      rethrow; // Expose the actual error to caller
    }
  }

  /// Upload an avatar image file and update the profile.
  /// Returns the public URL of the uploaded avatar.
  Future<String?> uploadAvatar(File imageFile) async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      // Generate unique filename
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to storage
      await _client.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final url = _client.storage.from('avatars').getPublicUrl(fileName);

      // Update profile with new avatar URL
      await updateProfile({'avatar_url': url});

      return url;
    } catch (e) {
      debugPrint('Upload Avatar Error: $e');
      return null;
    }
  }

  /// Upload an avatar from bytes (for web compatibility).
  Future<String?> uploadAvatarBytes(Uint8List bytes, String extension) async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from('avatars').getPublicUrl(fileName);

      await updateProfile({'avatar_url': url});

      return url;
    } catch (e) {
      debugPrint('Upload Avatar Bytes Error: $e');
      return null;
    }
  }

  /// Delete the current user's avatar.
  Future<bool> deleteAvatar() async {
    final userId = SupabaseService.userId;
    if (userId == null) return false;

    try {
      // List all files in user's avatar folder
      final files = await _client.storage.from('avatars').list(path: userId);

      // Delete all avatar files
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from('avatars').remove(paths);
      }

      // Clear avatar URL in profile
      await updateProfile({'avatar_url': null});

      return true;
    } catch (e) {
      debugPrint('Delete Avatar Error: $e');
      return false;
    }
  }
}

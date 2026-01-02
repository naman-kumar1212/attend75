import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for managing user settings in Supabase.
/// Handles CRUD operations for user preferences.
class SettingsService {
  final SupabaseClient _client = SupabaseService.client;

  /// Get the current user's settings.
  Future<Map<String, dynamic>?> getSettings() async {
    final userId = SupabaseService.userId;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Get Settings Error: $e');
      return null;
    }
  }

  /// Update the current user's settings.
  Future<bool> updateSettings(Map<String, dynamic> data) async {
    final userId = SupabaseService.userId;
    if (userId == null) return false;

    try {
      await _client.from('user_settings').update(data).eq('user_id', userId);
      return true;
    } catch (e) {
      debugPrint('Update Settings Error: $e');
      return false;
    }
  }

  /// Upsert settings (create if not exists, update if exists).
  Future<bool> upsertSettings(Map<String, dynamic> data) async {
    final userId = SupabaseService.userId;
    if (userId == null) return false;

    try {
      data['user_id'] = userId;
      await _client.from('user_settings').upsert(data, onConflict: 'user_id');
      return true;
    } catch (e) {
      debugPrint('Upsert Settings Error: $e');
      return false;
    }
  }

  /// Update a single setting value.
  Future<bool> updateSetting(String key, dynamic value) async {
    return await updateSettings({key: value});
  }

  /// Get a single setting value.
  Future<dynamic> getSetting(String key) async {
    final settings = await getSettings();
    return settings?[key];
  }
}

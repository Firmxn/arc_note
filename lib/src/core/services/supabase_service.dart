import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  SupabaseClient get client => _client;

  // Auth helpers
  Auth get auth => _client.auth;

  // Database helpers
  SupabaseQueryBuilder from(String table) => _client.from(table);

  // Storage helpers
  SupabaseStorageBuilder storage => _client.storage;

  // Realtime subscription
  RealtimeChannel channel(String name) => _client.channel(name);

  // Utility methods
  Future<bool> isConnected() async {
    try {
      await _client.from('pages').select('count', count: 'exact');
      return true;
    } catch (e) {
      AppLogger.error('Supabase connection failed', e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      return {
        'id': user.id,
        'email': user.email,
        'created_at': user.createdAt?.toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('Failed to get current user', e);
      return null;
    }
  }
}

// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});
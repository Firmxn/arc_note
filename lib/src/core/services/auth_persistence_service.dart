import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class AuthPersistenceService {
  static const String _sessionKey = 'auth_session';
  static const String _userKey = 'auth_user';
  static const String _lastActiveKey = 'last_active_time';

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('AuthPersistenceService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize AuthPersistenceService', e);
      rethrow;
    }
  }

  // Save session data
  Future<void> saveSession(Session session, User user) async {
    try {
      if (_prefs == null) await initialize();

      final sessionData = {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
        'expires_at': session.expiresAt?.toIso8601String(),
        'token_type': session.tokenType,
      };

      await _prefs!.setString(_sessionKey, jsonEncode(sessionData));
      await _prefs!.setString(_userKey, jsonEncode(_userToJson(user)));
      await _prefs!.setString(_lastActiveKey, DateTime.now().toIso8601String());

      AppLogger.info('Session saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save session', e);
    }
  }

  // Get saved session data
  Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      if (_prefs == null) await initialize();

      final sessionString = _prefs!.getString(_sessionKey);
      if (sessionString == null) return null;

      final sessionData = jsonDecode(sessionString) as Map<String, dynamic>;

      // Check if session is still valid
      final expiresAtString = sessionData['expires_at'] as String?;
      if (expiresAtString != null) {
        final expiresAt = DateTime.parse(expiresAtString);
        if (DateTime.now().isAfter(expiresAt)) {
          await clearSession();
          return null;
        }
      }

      return sessionData;
    } catch (e) {
      AppLogger.error('Failed to get saved session', e);
      return null;
    }
  }

  // Get saved user data
  Future<Map<String, dynamic>?> getSavedUser() async {
    try {
      if (_prefs == null) await initialize();

      final userString = _prefs!.getString(_userKey);
      if (userString == null) return null;

      return jsonDecode(userString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to get saved user', e);
      return null;
    }
  }

  // Check if user was recently active (within last 7 days)
  Future<bool> isRecentlyActive() async {
    try {
      if (_prefs == null) await initialize();

      final lastActiveString = _prefs!.getString(_lastActiveKey);
      if (lastActiveString == null) return false;

      final lastActive = DateTime.parse(lastActiveString);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      return lastActive.isAfter(sevenDaysAgo);
    } catch (e) {
      AppLogger.error('Failed to check recent activity', e);
      return false;
    }
  }

  // Update last active time
  Future<void> updateLastActive() async {
    try {
      if (_prefs == null) await initialize();

      await _prefs!.setString(_lastActiveKey, DateTime.now().toIso8601String());
    } catch (e) {
      AppLogger.error('Failed to update last active time', e);
    }
  }

  // Clear session data
  Future<void> clearSession() async {
    try {
      if (_prefs == null) await initialize();

      await _prefs!.remove(_sessionKey);
      await _prefs!.remove(_userKey);
      // Keep lastActiveKey for analytics

      AppLogger.info('Session cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear session', e);
    }
  }

  // Check if session exists
  Future<bool> hasValidSession() async {
    try {
      final sessionData = await getSavedSession();
      final userData = await getSavedUser();

      return sessionData != null && userData != null;
    } catch (e) {
      AppLogger.error('Failed to check session validity', e);
      return false;
    }
  }

  // Convert User to JSON
  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'user_metadata': user.userMetadata,
      'app_metadata': user.appMetadata,
      'created_at': user.createdAt?.toIso8601String(),
      'confirmed_at': user.confirmedAt?.toIso8601String(),
    };
  }

  // Get authentication statistics
  Future<Map<String, dynamic>> getAuthStats() async {
    try {
      if (_prefs == null) await initialize();

      final hasSession = _prefs!.containsKey(_sessionKey);
      final hasUser = _prefs!.containsKey(_userKey);
      final lastActiveString = _prefs!.getString(_lastActiveKey);

      String lastActiveFormatted = 'Never';
      if (lastActiveString != null) {
        final lastActive = DateTime.parse(lastActiveString);
        lastActiveFormatted = lastActiveFormatted;
      }

      return {
        'has_session': hasSession,
        'has_user': hasUser,
        'last_active': lastActiveFormatted,
        'is_recently_active': await isRecentlyActive(),
      };
    } catch (e) {
      AppLogger.error('Failed to get auth stats', e);
      return {};
    }
  }
}
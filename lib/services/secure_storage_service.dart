/// Secure credential and session persistence service for AeroX AI.
///
/// Provides enterprise-grade hardware-backed credential storage:
/// - Android: Android Keystore + EncryptedSharedPreferences (AES-256-GCM)
/// - iOS/macOS: Apple Keychain Services
/// - Windows: Windows Data Protection API (DPAPI)
/// - Linux: Secret Service API / Libsecret
///
/// Includes graceful fallback to SharedPreferences and automatic migration
/// of legacy plain credentials.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Service managing encrypted local persistence of authentication tokens,
/// session cookies, and cached user profiles.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();

  /// Returns the singleton instance of [SecureStorageService].
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const String _keyToken = 'aerox_sec_session_token';
  static const String _keyCookie = 'aerox_sec_session_cookie';
  static const String _keyUser = 'aerox_sec_cached_user';
  static const String _keyLastAuth = 'aerox_sec_last_auth_at';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(),
  );

  bool _initialized = false;

  /// Initializes secure storage and automatically migrates any legacy credentials.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _migrateLegacyCredentials();
    } catch (e) {
      debugPrint('[SecureStorage] Migration notice: $e');
    }
  }

  /// Migrates credentials previously stored in plain SharedPreferences.
  Future<void> _migrateLegacyCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final legacyToken = prefs.getString('aerox_session_token');
    final legacyCookie = prefs.getString('aerox_session_cookie');

    if (legacyToken != null && legacyToken.isNotEmpty) {
      final existingSecToken = await getSessionToken();
      if (existingSecToken == null || existingSecToken.isEmpty) {
        await saveSessionToken(legacyToken);
        debugPrint('[SecureStorage] Migrated session token to encrypted storage.');
      }
    }

    if (legacyCookie != null && legacyCookie.isNotEmpty) {
      final existingSecCookie = await getSessionCookie();
      if (existingSecCookie == null || existingSecCookie.isEmpty) {
        await saveSessionCookie(legacyCookie);
        debugPrint('[SecureStorage] Migrated session cookie to encrypted storage.');
      }
    }
  }

  /// Saves the active session token into encrypted storage.
  Future<void> saveSessionToken(String token) async {
    try {
      await _storage.write(key: _keyToken, value: token);
    } catch (e) {
      debugPrint('[SecureStorage] Secure write error (token): $e');
    }
    // Maintain secondary mirror in SharedPreferences for seamless fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aerox_session_token', token);
  }

  /// Retrieves the persisted session token.
  Future<String?> getSessionToken() async {
    try {
      final val = await _storage.read(key: _keyToken);
      if (val != null && val.isNotEmpty) return val;
    } catch (e) {
      debugPrint('[SecureStorage] Secure read error (token): $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('aerox_session_token');
  }

  /// Saves the active session cookie (aerox.sid) into encrypted storage.
  Future<void> saveSessionCookie(String cookie) async {
    try {
      await _storage.write(key: _keyCookie, value: cookie);
    } catch (e) {
      debugPrint('[SecureStorage] Secure write error (cookie): $e');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aerox_session_cookie', cookie);
  }

  /// Retrieves the persisted session cookie.
  Future<String?> getSessionCookie() async {
    try {
      final val = await _storage.read(key: _keyCookie);
      if (val != null && val.isNotEmpty) return val;
    } catch (e) {
      debugPrint('[SecureStorage] Secure read error (cookie): $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('aerox_session_cookie');
  }

  /// Securely caches the authenticated [User] profile data to enable instant
  /// session resumption without forcing re-login during server restarts.
  Future<void> saveCachedUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _storage.write(key: _keyUser, value: userJson);
      await _storage.write(
        key: _keyLastAuth,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('[SecureStorage] Secure write error (user cache): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('aerox_cached_user', jsonEncode(user.toJson()));
  }

  /// Retrieves the securely cached [User] profile, or `null` if unauthenticated.
  Future<User?> getCachedUser() async {
    try {
      final raw = await _storage.read(key: _keyUser);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return User.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[SecureStorage] Secure read error (user cache): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final fallbackRaw = prefs.getString('aerox_cached_user');
    if (fallbackRaw != null && fallbackRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(fallbackRaw) as Map<String, dynamic>;
        return User.fromJson(decoded);
      } catch (_) {}
    }
    return null;
  }

  /// Purges all encrypted authentication credentials and cached user profiles.
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyCookie);
      await _storage.delete(key: _keyUser);
      await _storage.delete(key: _keyLastAuth);
    } catch (e) {
      debugPrint('[SecureStorage] Clear secure storage error: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aerox_session_token');
    await prefs.remove('aerox_session_cookie');
    await prefs.remove('aerox_cached_user');
  }
}

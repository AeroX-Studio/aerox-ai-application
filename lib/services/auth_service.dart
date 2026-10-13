/// Authentication and session lifecycle service for AeroX AI.
///
/// Manages user login, account registration, session restoration from disk,
/// native Google Sign-In, logout revocation, and reactive user profile state notifications.
library;

import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'google_auth_service.dart';
import 'platform_service.dart';

/// Service managing user authentication, sessions, and reactive profile state.
class AuthService {
  static final AuthService _instance = AuthService._internal();

  /// Returns the shared singleton instance of [AuthService].
  factory AuthService() => _instance;
  AuthService._internal() {
    _api.onSessionExpired = () {
      currentUser.value = null;
    };
  }

  final ApiService _api = ApiService();
  final GoogleAuthService _googleAuth = GoogleAuthService();

  /// Notifier exposing the currently authenticated [User], or `null` if guest.
  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  /// Whether a user is currently authenticated with an active session.
  bool get isAuthenticated => currentUser.value != null;

  /// Restores session state from persistent storage if valid tokens exist.
  ///
  /// Returns `true` if a valid session exists and the profile was restored.
  Future<bool> restoreSession() async {
    // Only attempt restoration if session credentials exist in storage
    if ((_api.sessionToken == null || _api.sessionToken!.isEmpty) &&
        (_api.sessionCookie == null || _api.sessionCookie!.isEmpty)) {
      currentUser.value = null;
      return false;
    }

    try {
      final res = await _api.get('/api/app/auth/me');
      if (res is Map<String, dynamic> && res['id'] != null) {
        currentUser.value = User.fromJson(res);
        return true;
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      // If server explicitly rejected authentication, clear dead credentials
      if (msg.contains('401') ||
          msg.contains('unauthenticated') ||
          msg.contains('session expired') ||
          msg.contains('account disabled') ||
          msg.contains('authentication required')) {
        await _api.clearSession();
      }
      currentUser.value = null;
    }
    return false;
  }

  /// Authenticates a user using their [login] and [password].
  ///
  /// Persists session tokens and returns the authenticated [User].
  Future<User> login({
    required String login,
    required String password,
    String? platform,
    String? deviceId,
    String? appVersion,
    String? osVersion,
    String? deviceModel,
  }) async {
    final res = await _api.post('/api/app/auth/login', {
      'login': login.trim(),
      'password': password,
      'platform': platform,
      'deviceId': deviceId,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
    });

    if (res is Map<String, dynamic> && res['success'] == true && res['user'] != null) {
      if (res['sessionToken'] != null) {
        await _api.setSession(token: res['sessionToken'].toString());
      }
      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      currentUser.value = user;
      return user;
    }

    throw Exception('Login failed. Please check your credentials.');
  }

  /// Registers a new user account with [email], [username], and [password].
  Future<User> register({
    required String email,
    required String username,
    required String password,
    String? platform,
    String? deviceId,
    String? appVersion,
  }) async {
    final res = await _api.post('/api/app/auth/register', {
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'password': password,
      'platform': platform,
      'deviceId': deviceId,
      'appVersion': appVersion,
    });

    if (res is Map<String, dynamic> && res['success'] == true && res['user'] != null) {
      if (res['sessionToken'] != null) {
        await _api.setSession(token: res['sessionToken'].toString());
      }
      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      currentUser.value = user;
      return user;
    }

    throw Exception('Registration failed.');
  }

  /// Authenticates a user via native Google Sign-In on Android.
  ///
  /// Opens the native Google Account chooser, obtains an OpenID Connect
  /// ID token, transmits it securely to the AeroX backend for token verification,
  /// creates or restores the user session, and updates application state.
  ///
  /// Returns `null` if the user cancelled the Google account chooser.
  Future<User?> signInWithGoogle() async {
    final idToken = await _googleAuth.getIdToken();
    if (idToken == null) {
      // User cancelled account selection
      return null;
    }

    final platformService = PlatformService();
    final platform = platformService.currentPlatform;
    final deviceId = await platformService.getDeviceId();
    final osVersion = platformService.currentOsVersion;
    final deviceModel = kIsWeb ? 'Web Client' : 'Android Client';

    return await loginWithGoogle(
      idToken: idToken,
      platform: platform,
      deviceId: deviceId,
      appVersion: '1.0.0',
      osVersion: osVersion,
      deviceModel: deviceModel,
    );
  }

  /// Authenticates or registers a user on the AeroX backend using a verified [idToken].
  Future<User> loginWithGoogle({
    required String idToken,
    String? code,
    String? platform,
    String? deviceId,
    String? appVersion,
    String? osVersion,
    String? deviceModel,
  }) async {
    final res = await _api.post('/api/app/auth/google', {
      'idToken': idToken,
      'code': ?code,
      'platform': platform,
      'deviceId': deviceId,
      'appVersion': appVersion,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
    });

    if (res is Map<String, dynamic> && res['success'] == true && res['user'] != null) {
      if (res['sessionToken'] != null) {
        await _api.setSession(token: res['sessionToken'].toString());
      }
      final user = User.fromJson(res['user'] as Map<String, dynamic>);
      currentUser.value = user;
      return user;
    }

    throw Exception(res['error'] ?? res['message'] ?? 'Google authentication failed.');
  }

  /// Links a Google account natively to the active authenticated profile.
  ///
  /// Returns `null` if the user cancelled the account selection.
  Future<Map<String, dynamic>?> linkGoogleAccountWithNative() async {
    final idToken = await _googleAuth.getIdToken();
    if (idToken == null) {
      return null;
    }
    return await linkGoogleAccount(idToken: idToken);
  }

  /// Connects and links a Google account to the active authenticated profile.
  Future<Map<String, dynamic>> linkGoogleAccount({
    required String idToken,
    String? code,
  }) async {
    final res = await _api.post('/api/app/auth/google/link', {
      'idToken': idToken,
      'code': ?code,
    });

    if (res is Map<String, dynamic> && res['success'] == true) {
      if (res['user'] != null) {
        final updated = User.fromJson(res['user'] as Map<String, dynamic>);
        currentUser.value = updated;
      } else if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          isGoogleConnected: true,
          googleEmail: res['googleEmail']?.toString() ?? currentUser.value!.email,
        );
      }
      return res;
    }
    throw Exception(res['error'] ?? res['message'] ?? 'Failed to link Google account.');
  }

  /// Disconnects the linked Google account from the active profile.
  Future<Map<String, dynamic>> disconnectGoogleAccount() async {
    final res = await _api.post('/api/app/auth/google/disconnect', {});
    if (res is Map<String, dynamic> && res['success'] == true) {
      if (currentUser.value != null) {
        currentUser.value = currentUser.value!.copyWith(
          isGoogleConnected: false,
          googleEmail: null,
          authProvider: 'local',
        );
      }
      return res;
    }
    throw Exception(res['error'] ?? res['message'] ?? 'Failed to disconnect Google account.');
  }

  /// Revokes active session tokens and clears cached credentials locally and on the server.
  Future<void> logout() async {
    try {
      await _api.post('/api/app/auth/logout');
    } catch (_) {}
    await _api.clearSession();
    await _googleAuth.signOut();
    currentUser.value = null;
  }

  /// Updates the reactive credit balances of the active user.
  void updateCredits({required double available, double? used, double? total}) {
    final curr = currentUser.value;
    if (curr == null) return;
    currentUser.value = curr.copyWith(
      totalCredits: total ?? curr.totalCredits,
      usedCredits: used ?? curr.usedCredits,
      availableCredits: available,
    );
  }

  /// Refreshes the user profile from the server.
  Future<void> refreshProfile() async {
    await restoreSession();
  }

  /// Redeems a gift card or promotional voucher code.
  Future<Map<String, dynamic>> redeemVoucher(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a voucher code.');
    }
    final res = await _api.post('/api/redeem', {'code': trimmed});
    if (res is Map<String, dynamic>) {
      await refreshProfile();
      return res;
    }
    throw Exception('Failed to process voucher redemption.');
  }
}

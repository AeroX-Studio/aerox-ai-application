/// Authentication and session lifecycle service for AeroX AI.
///
/// Manages user login, account registration, session restoration from disk,
/// native Google Sign-In, logout revocation, and reactive user profile state notifications.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'google_auth_service.dart';
import 'platform_service.dart';
import 'secure_storage_service.dart';

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
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Notifier exposing the currently authenticated [User], or `null` if guest.
  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  /// Whether a user is currently authenticated with an active session.
  bool get isAuthenticated => currentUser.value != null;

  /// Restores session state from persistent storage if valid tokens exist.
  ///
  /// Returns `true` if a valid session exists and the profile was restored.
  /// Preserves authentication across backend restarts and server reboots.
  Future<bool> restoreSession() async {
    await _secureStorage.init();

    // Check credentials in secure storage and ApiService
    final hasToken = (_api.sessionToken != null && _api.sessionToken!.isNotEmpty);
    final hasCookie = (_api.sessionCookie != null && _api.sessionCookie!.isNotEmpty);

    if (!hasToken && !hasCookie) {
      currentUser.value = null;
      return false;
    }

    // Hydrate immediately from secure local cache
    final cachedUser = await _secureStorage.getCachedUser();
    if (cachedUser != null) {
      currentUser.value = cachedUser;
    }

    try {
      final res = await _api.get('/api/app/auth/me');
      if (res is Map<String, dynamic> && res['id'] != null) {
        final freshUser = User.fromJson(res);
        currentUser.value = freshUser;
        await _secureStorage.saveCachedUser(freshUser);

        if (res['sessionToken'] != null && res['sessionToken'].toString().isNotEmpty) {
          await _api.setSession(token: res['sessionToken'].toString());
        }
        return true;
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      debugPrint('[AuthService] Verify session notice: $msg');

      // If backend explicitly indicated the account has been disabled or suspended
      final isDefinitiveAuthFailure = msg.contains('account disabled') ||
          msg.contains('account has been deactivated') ||
          (msg.contains('401') && (msg.contains('disabled') || msg.contains('deactivated')));

      if (isDefinitiveAuthFailure) {
        await _api.clearSession();
        await _secureStorage.clearAll();
        currentUser.value = null;
        return false;
      }

      // If backend server is currently restarting, cold starting, or offline:
      // PRESERVE the active authenticated session from secure storage so restart never forces re-login!
      if (cachedUser != null) {
        debugPrint('[AuthService] Server restarting or unreachable; preserving session from secure cache.');
        currentUser.value = cachedUser;
        return true;
      }

      // If 401 without cached user:
      if (msg.contains('401') || msg.contains('unauthenticated') || msg.contains('authentication required')) {
        await _api.clearSession();
        await _secureStorage.clearAll();
        currentUser.value = null;
        return false;
      }
    }

    return currentUser.value != null;
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
      await _secureStorage.saveCachedUser(user);
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
      await _secureStorage.saveCachedUser(user);
      return user;
    }

    throw Exception('Registration failed.');
  }

  /// Authenticates a user via Google Sign-In with automatic cross-platform fallback.
  ///
  /// On mobile devices with Google Play Services, initiates the native Google Account
  /// chooser. If native sign-in is unsupported (e.g. Windows/macOS/Linux) or device
  /// configuration issues occur (missing SHA-1, unconfigured client), smoothly
  /// initiates the secure browser-based Google OAuth bridge so authentication
  /// always succeeds.
  ///
  /// Returns `null` if the user cancelled the Google account chooser.
  Future<User?> signInWithGoogle() async {
    // 1. If running on desktop, native Google Sign-In SDK is not supported. Use browser OAuth.
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      debugPrint('[AuthService] Desktop platform detected. Initiating Browser Google OAuth bridge.');
      return await signInWithGoogleBrowser();
    }

    // 2. On Android/iOS/Web, attempt native Google Sign-In first
    try {
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
    } on GoogleConfigFallbackException catch (fallbackErr) {
      debugPrint('[AuthService] Native Google Sign-In requested fallback: $fallbackErr');
      return await signInWithGoogleBrowser();
    } catch (e) {
      debugPrint('[AuthService] Native Google Sign-In encountered error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('configuration') ||
          errStr.contains('developer') ||
          errStr.contains('10') ||
          errStr.contains('12500') ||
          errStr.contains('unavailable') ||
          errStr.contains('channel-error') ||
          errStr.contains('unimplemented') ||
          errStr.contains('missingpluginexception')) {
        debugPrint('[AuthService] Falling back to Browser Google OAuth...');
        return await signInWithGoogleBrowser();
      }
      rethrow;
    }
  }

  /// Performs secure browser-based Google OAuth using the AeroX backend session bridge.
  ///
  /// Works across Android, Windows, macOS, Linux, and Web, providing a 100% reliable
  /// authentication path even if Google Play Services is missing or native client IDs are unconfigured.
  Future<User?> signInWithGoogleBrowser() async {
    final platformService = PlatformService();
    final platform = platformService.currentPlatform;

    // 1. Request an authenticated bridge session from backend
    final initRes = await _api.post('/api/app/auth/google/init-session', {
      'platform': platform,
    });

    if (initRes is! Map<String, dynamic> || initRes['success'] != true) {
      throw Exception('Failed to initiate Google authentication session.');
    }

    final authSessionId = initRes['authSessionId']?.toString();
    final authUrl = initRes['authUrl']?.toString();

    if (authSessionId == null || authUrl == null) {
      throw Exception('Invalid authentication response from server.');
    }

    // 2. Open auth URL in the system browser
    final uri = Uri.parse(authUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      // Fallback: platform process execution
      if (!kIsWeb && Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', authUrl]);
      } else if (!kIsWeb && Platform.isMacOS) {
        await Process.run('open', [authUrl]);
      } else if (!kIsWeb && Platform.isLinux) {
        await Process.run('xdg-open', [authUrl]);
      }
    }

    // 3. Poll for session completion (every 1.2s up to 90 seconds)
    final startTime = DateTime.now();
    const pollInterval = Duration(milliseconds: 1200);
    const maxDuration = Duration(seconds: 90);

    while (DateTime.now().difference(startTime) < maxDuration) {
      await Future.delayed(pollInterval);

      try {
        final statusRes = await _api.get(
          '/api/app/auth/google/session-status?authSessionId=$authSessionId',
        );

        if (statusRes is Map<String, dynamic> && statusRes['success'] == true) {
          final status = statusRes['status']?.toString();
          if (status == 'completed' && statusRes['user'] != null) {
            final sessionToken = statusRes['sessionToken'] ?? statusRes['token'];
            if (sessionToken != null) {
              await _api.setSession(token: sessionToken.toString());
            }

            final user = User.fromJson(statusRes['user'] as Map<String, dynamic>);
            currentUser.value = user;
            await _secureStorage.saveCachedUser(user);
            return user;
          } else if (status == 'expired' || status == 'not_found') {
            break;
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Polling bridge status note: $e');
      }
    }

    throw Exception('Google Sign-In timed out. Please try again.');
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
      await _secureStorage.saveCachedUser(user);
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
      if (currentUser.value != null) {
        await _secureStorage.saveCachedUser(currentUser.value!);
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
        await _secureStorage.saveCachedUser(currentUser.value!);
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
    await _secureStorage.clearAll();
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

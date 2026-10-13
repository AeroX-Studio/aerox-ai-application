/// Native Google OAuth service for AeroX AI native applications.
///
/// Manages Google Sign-In interaction with Google Play Services on Android and iOS,
/// retrieving OpenID Connect ID Tokens for AeroX AI backend authentication.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Custom exception thrown when native Google authentication encounters
/// a configuration or platform restriction that necessitates falling back to Web OAuth.
class GoogleConfigFallbackException implements Exception {
  final String message;
  final dynamic cause;
  const GoogleConfigFallbackException(this.message, [this.cause]);

  @override
  String toString() => message;
}

/// Service managing native Google authentication lifecycle and token acquisition.
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();

  /// Returns the singleton instance of [GoogleAuthService].
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  bool _initialized = false;

  /// Returns true if native Google Sign-In SDK is supported on the host OS.
  bool get isNativeSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: AppConfig.googleClientId,
      );
      _initialized = true;
    }
  }

  /// Initiates native Google account selection and retrieves an ID token.
  ///
  /// Returns `null` if the user voluntarily dismissed or cancelled account selection.
  /// Throws [GoogleConfigFallbackException] if native sign-in is unsupported or misconfigured,
  /// prompting an automatic fallback to the browser OAuth bridge.
  Future<String?> getIdToken() async {
    if (!isNativeSupported) {
      throw const GoogleConfigFallbackException(
        'Native Google Sign-In SDK is only available on Android, iOS, and Web. Using browser authentication.',
      );
    }

    try {
      await _ensureInitialized();

      // Initiate authentication with required OpenID Connect scopes
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email', 'profile', 'openid'],
      );

      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleConfigFallbackException(
          'Google authentication could not acquire a valid security token. '
          'Falling back to browser authentication.',
        );
      }

      return idToken.trim();
    } on GoogleSignInException catch (e) {
      debugPrint('[GoogleAuthService] GoogleSignInException: ${e.code} - ${e.description}');

      // Check for cancel / interrupt
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        final desc = (e.description ?? '').toLowerCase();
        // If "canceled" was caused by missing credential or developer setup, trigger fallback
        if (desc.contains('credential') ||
            desc.contains('developer') ||
            desc.contains('10') ||
            desc.contains('12500')) {
          throw GoogleConfigFallbackException(
            'Google Sign-In configuration error on device. Switching to browser authentication.',
            e,
          );
        }
        // Genuine user cancellation
        return null;
      }

      if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw GoogleConfigFallbackException(
          'Google Sign-In UI is unavailable on this device. Switching to browser authentication.',
          e,
        );
      }

      // Any other GoogleSignInException (developerError, etc.) triggers fallback
      throw GoogleConfigFallbackException(
        'Google Sign-In notice: ${e.description ?? e.code.name}. Switching to browser authentication.',
        e,
      );
    } catch (e) {
      debugPrint('[GoogleAuthService] Unexpected error: $e');
      if (e is GoogleConfigFallbackException) rethrow;

      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') && !msg.contains('credential')) {
        return null;
      }

      // Unknown or platform channel errors trigger fallback
      throw GoogleConfigFallbackException(
        'Native Google Sign-In encountered an issue: $e. Switching to browser authentication.',
        e,
      );
    }
  }

  /// Clears any cached Google account state on the local device.
  Future<void> signOut() async {
    if (!isNativeSupported) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google signOut: $e');
    }
  }
}

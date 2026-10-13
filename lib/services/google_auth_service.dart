/// Native Google OAuth service for AeroX AI native applications.
///
/// Manages Google Sign-In interaction with Google Play Services on Android,
/// retrieving OpenID Connect ID Tokens for AeroX AI backend authentication.
library;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Service managing native Google authentication lifecycle and token acquisition.
class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();

  /// Returns the singleton instance of [GoogleAuthService].
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  bool _initialized = false;

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
  /// Throws a user-friendly [Exception] on network or configuration errors.
  Future<String?> getIdToken() async {
    try {
      await _ensureInitialized();

      // Clear any prior cached session so account selection prompt always appears
      await signOut();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();

      final String? idToken = account.authentication.idToken;

      if (idToken == null || idToken.trim().isEmpty) {
        throw Exception(
          'Google authentication could not acquire a valid security token. '
          'Please ensure Google Play Services is active on your device.',
        );
      }

      return idToken.trim();
    } on GoogleSignInException catch (e) {
      debugPrint('[GoogleAuthService] GoogleSignInException: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // User cancelled account selection
        return null;
      }
      if (e.code == GoogleSignInExceptionCode.uiUnavailable) {
        throw Exception('Google Sign-In UI is currently unavailable. Please try again.');
      }
      throw Exception('Google Sign-In error: ${e.description ?? e.code.name}');
    } catch (e) {
      debugPrint('[GoogleAuthService] Unexpected error: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('interrupted')) {
        return null;
      }
      if (e is Exception) rethrow;
      throw Exception('Unexpected error during Google Sign-In: $e');
    }
  }

  /// Clears any cached Google account state on the local device.
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google signOut: $e');
    }
  }
}

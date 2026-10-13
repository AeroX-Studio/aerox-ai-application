import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/services/google_auth_service.dart';
import 'package:aeroxai/models/user.dart';

void main() {
  group('Google Auth & Cross-Platform Bridge Tests', () {
    test('GoogleAuthService detects platform capability correctly', () {
      final googleAuth = GoogleAuthService();
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        expect(googleAuth.isNativeSupported, isFalse);
      } else if (Platform.isAndroid || Platform.isIOS) {
        expect(googleAuth.isNativeSupported, isTrue);
      }
    });

    test('GoogleConfigFallbackException formats message and cause properly', () {
      const fallbackException = GoogleConfigFallbackException(
        'Falling back to browser authentication.',
        'developer_error',
      );
      expect(fallbackException.toString(), equals('Falling back to browser authentication.'));
      expect(fallbackException.cause, equals('developer_error'));
    });

    test('User handles Google authentication fields and null safe attributes', () {
      final googleUserJson = {
        'id': 'usr_google_123',
        'email': 'developer@gmail.com',
        'username': 'developer',
        'displayName': 'Google Developer',
        'role': 'user',
        'totalCredits': 100,
        'usedCredits': 0,
        'availableCredits': 100,
        'avatarUrl': 'https://lh3.googleusercontent.com/a/sample',
        'googleEmail': 'developer@gmail.com',
        'isGoogleConnected': true,
        'hasPassword': false,
        'authProvider': 'google',
      };

      final user = User.fromJson(googleUserJson);
      expect(user.id, equals('usr_google_123'));
      expect(user.email, equals('developer@gmail.com'));
      expect(user.googleEmail, equals('developer@gmail.com'));
      expect(user.isGoogleConnected, isTrue);
      expect(user.hasPassword, isFalse);
      expect(user.authProvider, equals('google'));
    });
  });
}

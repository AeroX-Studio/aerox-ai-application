import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/models/user.dart';

void main() {
  group('Secure Session & User Persistence Tests', () {
    test('User round-trip serialization preserves all session state', () {
      final originalUser = User(
        id: 'usr_abc_789',
        email: 'pilot@aerox.ai',
        username: 'aeroxpilot',
        displayName: 'AeroX Flight Lead',
        role: 'user',
        totalCredits: 2500.0,
        usedCredits: 340.0,
        availableCredits: 2160.0,
        avatarUrl: 'https://cdn.aerox.ai/avatars/pilot.webp',
        packageName: 'Pro Plan',
        packageSlug: 'pro',
        isGoogleConnected: true,
        googleEmail: 'pilot@gmail.com',
        authProvider: 'local+google',
        hasPassword: true,
        subscriptionStatus: 'active',
        subscriptionExpiresAt: '2026-11-15T00:00:00.000Z',
        subscriptionRemaining: '32 days remaining',
        subscriptionSource: 'payment',
      );

      final jsonMap = originalUser.toJson();
      final restoredUser = User.fromJson(jsonMap);

      expect(restoredUser.id, equals(originalUser.id));
      expect(restoredUser.email, equals(originalUser.email));
      expect(restoredUser.username, equals(originalUser.username));
      expect(restoredUser.displayName, equals(originalUser.displayName));
      expect(restoredUser.role, equals(originalUser.role));
      expect(restoredUser.totalCredits, equals(originalUser.totalCredits));
      expect(restoredUser.usedCredits, equals(originalUser.usedCredits));
      expect(restoredUser.availableCredits, equals(originalUser.availableCredits));
      expect(restoredUser.avatarUrl, equals(originalUser.avatarUrl));
      expect(restoredUser.packageName, equals(originalUser.packageName));
      expect(restoredUser.packageSlug, equals(originalUser.packageSlug));
      expect(restoredUser.isGoogleConnected, equals(originalUser.isGoogleConnected));
      expect(restoredUser.googleEmail, equals(originalUser.googleEmail));
      expect(restoredUser.authProvider, equals(originalUser.authProvider));
      expect(restoredUser.hasPassword, equals(originalUser.hasPassword));
      expect(restoredUser.subscriptionStatus, equals(originalUser.subscriptionStatus));
      expect(restoredUser.isSubscriptionActive, isTrue);
      expect(restoredUser.hasActivePaidPlan, isTrue);
    });

    test('User copyWith preserves credentials and updates credits accurately', () {
      final user = User(
        id: 'usr_001',
        email: 'test@aerox.ai',
        username: 'testuser',
        displayName: 'Test User',
        role: 'user',
        totalCredits: 100.0,
        usedCredits: 20.0,
        availableCredits: 80.0,
      );

      final updated = user.copyWith(
        availableCredits: 75.0,
        usedCredits: 25.0,
      );

      expect(updated.id, equals('usr_001'));
      expect(updated.email, equals('test@aerox.ai'));
      expect(updated.availableCredits, equals(75.0));
      expect(updated.usedCredits, equals(25.0));
      expect(updated.totalCredits, equals(100.0));
    });
  });
}

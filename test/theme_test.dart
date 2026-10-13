import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/theme/aerox_colors.dart';
import 'package:aeroxai/theme/aerox_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AeroX Design System & Theme Tests', () {
    test('AeroXColors match canonical design system values', () {
      expect(AeroXColors.bgPrimary, equals(const Color(0xFF000000)));
      expect(AeroXColors.bgSecondary, equals(const Color(0xFF0A0A0A)));
      expect(AeroXColors.textPrimary, equals(const Color(0xFFFFFFFF)));
      expect(AeroXColors.textSecondary, equals(const Color(0xFFA0A0A0)));
      expect(AeroXColors.accent, equals(const Color(0xFFFFFFFF)));
      expect(AeroXColors.accentMuted, equals(const Color(0xFF888888)));
      expect(AeroXColors.error, equals(const Color(0xFFF87171)));
      expect(AeroXColors.success, equals(const Color(0xFF4ADE80)));
      expect(AeroXColors.warning, equals(const Color(0xFFFBBF24)));
      expect(AeroXColors.info, equals(const Color(0xFF60A5FA)));
    });

    test('darkTheme generates valid Material 3 theme data', () {
      final theme = AeroXTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.scaffoldBackgroundColor, equals(AeroXColors.bgPrimary));
    });
  });
}

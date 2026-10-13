import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/widgets/aerox_badge.dart';

void main() {
  group('AeroXBadge Widget Tests', () {
    testWidgets('renders badge text and icon properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AeroXBadge(
              text: 'Active Plan',
              type: AeroXBadgeType.success,
              icon: Icons.check_circle_outline,
            ),
          ),
        ),
      );

      expect(find.text('Active Plan'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders neutral badge without icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AeroXBadge(
              text: 'PRO',
              type: AeroXBadgeType.neutral,
            ),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}

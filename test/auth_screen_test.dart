import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/screens/auth_screen.dart';
import 'package:aeroxai/theme/aerox_theme.dart';

void main() {
  group('AuthScreen UI and Interaction Tests', () {
    testWidgets('renders brand title, logo, and Continue with Google button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroXTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AeroX'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('switches smoothly between Sign In and Create Account tabs', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroXTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Create Account
      final createAccountTab = find.text('Create Account');
      await tester.tap(createAccountTab);
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Tap Sign In tab
      final signInTab = find.text('Sign In').first;
      await tester.tap(signInTab);
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Email or Username'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is tapped', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AeroXTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final visibilityBtn = find.byTooltip('Show password');
      expect(visibilityBtn, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    const viewports = [320.0, 360.0, 375.0, 390.0, 412.0, 768.0, 1024.0];
    for (final width in viewports) {
      testWidgets('renders AuthScreen cleanly without overflow at ${width.toInt()}px width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        FlutterErrorDetails? caughtDetails;
        final oldOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
          oldOnError?.call(details);
        };
        try {
          await tester.pumpWidget(
            MaterialApp(
              theme: AeroXTheme.darkTheme,
              home: const AuthScreen(),
            ),
          );
          await tester.pumpAndSettle();
        } finally {
          FlutterError.onError = oldOnError;
        }

        if (caughtDetails != null) {
          debugPrint('WIDTH $width CAUGHT DETAILS:\n${caughtDetails!.toDiagnosticsNode().toStringDeep()}');
        }
        final err = tester.takeException();
        expect(err, isNull);
        expect(find.text('Continue with Google'), findsOneWidget);
      });
    }
  });
}

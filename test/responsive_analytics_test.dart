import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeroxai/models/ai_model.dart';
import 'package:aeroxai/models/user.dart';
import 'package:aeroxai/screens/dashboard_screen.dart';
import 'package:aeroxai/services/auth_service.dart';
import 'package:aeroxai/theme/aerox_theme.dart';
import 'package:aeroxai/widgets/model_selector_modal.dart';

void main() {
  const targetWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 768.0, 1024.0, 1440.0];

  final List<AIModel> testModels = [
    AIModel(
      id: 'mod_pulse',
      internalModelId: 'aerox-pulse-fast',
      apiModelId: 'aerox-pulse-fast',
      publicName: 'AeroX-Pulse 3.1 Neural Turbo High Precision Extra Long',
      publicDescription: 'Ultra-fast low-latency reasoning model designed for responsive code generation.',
      badge: 'PRO',
      isFreeEnabled: false,
      supportsVision: true,
    ),
    AIModel(
      id: 'mod_apex',
      internalModelId: 'aerox-apex',
      apiModelId: 'aerox-apex',
      publicName: 'AeroX Apex 4.0 Omni Intelligence Flagship',
      publicDescription: 'Top-tier deep reasoning architecture with multimodal vision synthesis.',
      badge: 'FLAGSHIP',
      isFreeEnabled: false,
      supportsVision: true,
    ),
    AIModel(
      id: 'mod_free',
      internalModelId: 'aerox-free',
      apiModelId: 'aerox-free',
      publicName: 'AeroX Standard Base',
      publicDescription: 'Standard model with zero credit usage.',
      badge: 'FREE',
      isFreeEnabled: true,
      supportsVision: false,
    ),
  ];

  setUp(() {
    AuthService().currentUser.value = User(
      id: 'usr_test',
      email: 'tester@aerox.ai',
      username: 'tester',
      displayName: 'Alex Mercer',
      role: 'user',
      totalCredits: 100.0,
      usedCredits: 25.5,
      availableCredits: 74.5,
      packageName: 'Free Starter Plan',
      packageSlug: 'free',
      authProvider: 'local',
      hasPassword: true,
      isGoogleConnected: false,
    );
  });

  group('ModelSelectorModal Responsive Layout Tests', () {
    for (final width in targetWidths) {
      testWidgets('ModelSelectorModal renders cleanly at ${width.toInt()}px without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AeroXTheme.darkTheme,
            home: Scaffold(
              body: ModelSelectorModal(
                models: testModels,
                selectedModelId: 'mod_pulse',
                onSelect: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'Expected zero overflow exceptions at ${width.toInt()}px');
        expect(find.text('AI Intelligence Model'), findsOneWidget);
        expect(find.textContaining('AeroX-Pulse 3.1'), findsOneWidget);
        expect(find.textContaining('AeroX Apex 4.0'), findsOneWidget);
      });
    }
  });

  group('Usage Analytics & TopBar Responsive Layout Tests', () {
    for (final width in targetWidths) {
      testWidgets('Usage Analytics renders at ${width.toInt()}px without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AeroXTheme.darkTheme,
            home: const DashboardScreen(
              initialSection: DashboardSection.usage,
            ),
          ),
        );

        // Allow entrance staggered animations to settle and toast timers to elapse
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(seconds: 4));

        expect(tester.takeException(), isNull, reason: 'Expected zero overflow exceptions on Dashboard Usage at ${width.toInt()}px');
        expect(find.text('Usage & Token Analytics'), findsOneWidget);
        expect(find.text('Available Balance'), findsOneWidget);
        expect(find.text('Have a promo code or voucher?'), findsOneWidget);
      });
    }
  });
}

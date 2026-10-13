/// Root entrypoint for the AeroX AI cross-platform application.
///
/// Initializes framework bindings and mounts the primary [AeroXApp] widget
/// with the unified dark design system, Quicksand typography, and animated
/// page transitions matching the web platform dashboard.
library;

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/aerox_theme.dart';

/// Initializes application services and launches the Flutter application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AeroXApp());
}

/// The root application widget configuring themes, localization, and navigation.
class AeroXApp extends StatelessWidget {
  /// Creates the root [AeroXApp] widget.
  const AeroXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroX AI',
      debugShowCheckedModeBanner: false,
      theme: AeroXTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

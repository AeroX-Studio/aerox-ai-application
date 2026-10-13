/// Startup initialization, version check, and session restoration screen.
///
/// Delivers an ultra-premium, cinematic "billion-dollar AI application"
/// experience with:
/// - Deep cosmic black void background (#000000)
/// - Ambient drifting stardust constellation field with subtle luminescence
/// - Concentric celestial orbital gyroscope rings with animated photon node
/// - Pulsing multi-layered breathing radial intelligence core aura
/// - Glassmorphic metallic AeroX emblem pedestal with ambient levitation
/// - Staggered typographic reveal with Caacupe One brand mark and high-tech AI live badge
/// - Precision cybernetic beam progress indicator with micro-status readouts
/// - Cinematic camera zoom transition into Auth or Dashboard
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/platform_service.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

/// The initial splash screen handling app initialization and session checks
/// with a world-class cinematic brand entrance.
class SplashScreen extends StatefulWidget {
  /// Creates a [SplashScreen] widget.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String _statusText = 'Initializing neural core...';
  double _initProgress = 0.15;

  // ─── Animation Controllers ──────────────────────────────────────────
  late final AnimationController _entranceController;
  late final AnimationController _ambientPulseController;
  late final AnimationController _orbitalRotationController;
  late final AnimationController _levitationController;
  late final AnimationController _exitController;

  // ─── Staggered Entrance Curves ──────────────────────────────────────
  late final Animation<double> _orbitsFade;
  late final Animation<double> _emblemFade;
  late final Animation<double> _emblemScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _progressFade;

  // ─── Exit Zoom Animation ────────────────────────────────────────────
  late final Animation<double> _exitFade;
  late final Animation<double> _exitScale;

  @override
  void initState() {
    super.initState();

    // 1. Staggered Entrance (1400ms duration with luxurious ease-out curves)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _orbitsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _emblemFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.55, curve: Curves.easeOut),
      ),
    );

    _emblemScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.65, curve: Cubic(0.16, 1.0, 0.3, 1.0)),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.90, curve: Curves.easeOut),
      ),
    );

    // 2. Ambient Intelligence Core Breathing (3200ms infinite loop)
    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    // 3. Orbital Gyroscope Rotation (18s seamless rotation)
    _orbitalRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 18000),
    )..repeat();

    // 4. Subtle Floating Levitation (2800ms sine wave)
    _levitationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // 5. Cinematic Exit Zoom (450ms forward warp)
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeIn,
      ),
    );

    _exitScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInCubic,
      ),
    );

    // Trigger entrance sequence
    _entranceController.forward();

    // Initiate real app boot & session validation
    _initializeApp();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientPulseController.dispose();
    _orbitalRotationController.dispose();
    _levitationController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await ApiService().init();
      if (mounted) {
        setState(() {
          _statusText = 'Verifying platform telemetry...';
          _initProgress = 0.40;
        });
      }

      final platformStatus = await PlatformService()
          .checkPlatformStatus()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      if (platformStatus != null && platformStatus.isMaintenance) {
        if (!mounted) return;
        _showMaintenanceDialog(
          platformStatus.maintenanceMessage ??
              'System is currently undergoing scheduled platform upgrades.',
        );
        return;
      }

      if (mounted) {
        setState(() {
          _statusText = 'Restoring encrypted session...';
          _initProgress = 0.75;
        });
      }

      final isAuthenticated = await AuthService()
          .restoreSession()
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => AuthService().isAuthenticated,
          );

      if (!mounted) return;

      setState(() {
        _statusText = 'Neural engine synchronized.';
        _initProgress = 1.0;
      });

      // Ensure entrance animation has gracefully unfolded
      await _entranceController.forward();
      // Cinematic micro-pause allowing the user to appreciate the craft
      await Future.delayed(const Duration(milliseconds: 550));

      if (!mounted) return;

      // Cinematic exit zoom
      await _exitController.forward();

      if (!mounted) return;

      if (isAuthenticated) {
        PlatformService()
            .registerDeviceSession(
                userId: AuthService().currentUser.value?.id)
            .ignore();
        NotificationService().init().ignore();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const DashboardScreen(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: (_, a, _, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      } else {
        PlatformService().registerDeviceSession().ignore();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const AuthScreen(),
            transitionDuration: const Duration(milliseconds: 450),
            transitionsBuilder: (_, a, _, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      await _exitController.forward();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const AuthScreen(),
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    }
  }

  void _showMaintenanceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AeroXColors.borderPrimary),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction_rounded, color: AeroXColors.warning, size: 20),
            SizedBox(width: 8),
            Text(
              'System Maintenance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AeroXColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _initializeApp();
            },
            child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AeroXColors.bgPrimary,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _entranceController,
          _ambientPulseController,
          _orbitalRotationController,
          _levitationController,
          _exitController,
        ]),
        builder: (context, _) {
          final pulse = _ambientPulseController.value;
          final rotation = _orbitalRotationController.value;
          final levitationOffset = math.sin(_levitationController.value * math.pi) * 4.0;

          return ScaleTransition(
            scale: _exitScale,
            child: FadeTransition(
              opacity: _exitFade,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ─── 1. Deep Cosmic Stardust Constellation ─────────────────
                  CustomPaint(
                    painter: _StardustPainter(
                      progress: rotation,
                      pulse: pulse,
                    ),
                  ),

                  // ─── 2. Multi-Layered Central Intelligence Aura ───────────
                  Center(
                    child: Container(
                      width: 520,
                      height: 520,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.05 + 0.03 * pulse),
                            const Color(0xFF60A5FA).withValues(alpha: 0.015 + 0.015 * pulse),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // ─── 3. Main Centerpiece Scene ─────────────────────────────
                  Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Orbital System + Floating Emblem ───────────────
                          SizedBox(
                            width: 270,
                            height: 270,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Concentric High-Tech Orbital Rings
                                FadeTransition(
                                  opacity: _orbitsFade,
                                  child: CustomPaint(
                                    size: const Size(270, 270),
                                    painter: _OrbitalRingsPainter(
                                      rotation: rotation,
                                      pulse: pulse,
                                    ),
                                  ),
                                ),

                                // Floating Glassmorphic Emblem Pedestal
                                Transform.translate(
                                  offset: Offset(0, -levitationOffset),
                                  child: FadeTransition(
                                    opacity: _emblemFade,
                                    child: ScaleTransition(
                                      scale: _emblemScale,
                                      child: _buildEmblemPedestal(pulse),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Brand Title & Live Status Badge ────────────────
                          SlideTransition(
                            position: _textSlide,
                            child: FadeTransition(
                              opacity: _textFade,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'AeroX',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -1.0,
                                          height: 1.0,
                                          fontFamily: AeroXTheme.fontDisplay,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF111111),
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: const Color(0xFF222222),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.04),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Glowing emerald live pulse dot
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: AeroXColors.accent,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AeroXColors.accent.withValues(alpha: 0.6),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              'AI',
                                              style: AeroXTheme.tech(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.4,
                                                height: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Sleek luxury uppercase tagline
                                  Text(
                                    'AUTONOMOUS NEURAL INTELLIGENCE',
                                    style: AeroXTheme.tech(
                                      color: AeroXColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 52),

                          // ── Precision Cybernetic Beam Progress & Status ───
                          FadeTransition(
                            opacity: _progressFade,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Sleek Precision Progress Beam
                                _PrecisionBeam(progress: _initProgress),
                                const SizedBox(height: 16),

                                // Animated Micro-Status Text
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.2),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    _statusText,
                                    key: ValueKey(_statusText),
                                    style: GoogleFonts.quicksand(
                                      color: AeroXColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── 4. Architectural Bottom Version Stamp ─────────────────
                  Positioned(
                    bottom: 28,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: _progressFade,
                      child: Center(
                        child: Text(
                          'AEROX AI // SYSTEM ARCHITECTURE 2.5',
                          style: AeroXTheme.tech(
                            color: const Color(0xFF333338),
                            fontSize: 10,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the centerpiece glassmorphic emblem pedestal with soft luminous glow.
  Widget _buildEmblemPedestal(double pulse) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F13).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16 + 0.08 * pulse),
          width: 1.2,
        ),
        boxShadow: [
          // Deep drop shadow for elevation
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.9),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
          // Subtle celestial aura
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.10 + 0.06 * pulse),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Image.asset(
        'assets/images/logo_icon.png',
        fit: BoxFit.contain,
        semanticLabel: 'AeroX AI official emblem',
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ),
      ),
    );
  }
}

/// Precision cybernetic linear beam indicator.
class _PrecisionBeam extends StatelessWidget {
  final double progress;

  const _PrecisionBeam({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF202026), width: 0.6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final activeWidth = (constraints.maxWidth * progress.clamp(0.0, 1.0));
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: activeWidth,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF444444),
                      Color(0xFFFFFFFF),
                      Color(0xFF60A5FA),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter rendering ambient cosmic constellation stardust.
class _StardustPainter extends CustomPainter {
  final double progress;
  final double pulse;

  static final List<_StarPoint> _stars = _generateStars(40);

  _StardustPainter({
    required this.progress,
    required this.pulse,
  });

  static List<_StarPoint> _generateStars(int count) {
    final rng = math.Random(1337); // Deterministic seed
    return List.generate(count, (_) {
      return _StarPoint(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 1.4,
        alpha: 0.15 + rng.nextDouble() * 0.45,
        speed: 0.1 + rng.nextDouble() * 0.3,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final star in _stars) {
      // Gentle floating drift
      final currentY = (star.y - (progress * star.speed)) % 1.0;
      final currentX = (star.x + math.sin((progress + star.x) * math.pi * 2) * 0.01) % 1.0;

      final twinkle = 0.5 + 0.5 * math.sin((progress * 4 * math.pi) + (star.x * 10));
      final finalAlpha = (star.alpha * twinkle * (0.8 + 0.2 * pulse)).clamp(0.0, 1.0);

      paint.color = Colors.white.withValues(alpha: finalAlpha);

      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StardustPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

class _StarPoint {
  final double x;
  final double y;
  final double radius;
  final double alpha;
  final double speed;

  const _StarPoint({
    required this.x,
    required this.y,
    required this.radius,
    required this.alpha,
    required this.speed,
  });
}

/// Custom painter rendering concentric gyroscope orbital rings with moving photon tracer.
class _OrbitalRingsPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _OrbitalRingsPainter({
    required this.rotation,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Inner orbital track (radius: 76)
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07 + 0.03 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 76, innerPaint);

    // Outer orbital track (radius: 120) with fine ticks
    final outerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + 0.02 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(center, 120, outerPaint);

    // Cardinal tick marks at 0, 90, 180, 270 degrees
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16 + 0.06 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final p1 = Offset(
        center.dx + math.cos(angle) * 115,
        center.dy + math.sin(angle) * 115,
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * 125,
        center.dy + math.sin(angle) * 125,
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Revolving Photon Energy Node on outer ring
    final photonAngle = rotation * 2 * math.pi;
    final photonPos = Offset(
      center.dx + math.cos(photonAngle) * 120,
      center.dy + math.sin(photonAngle) * 120,
    );

    // Photon glow
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(photonPos, 6, glowPaint);

    // Photon core dot
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(photonPos, 2.2, corePaint);

    // Segmented rotating arc on inner ring
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 + 0.06 * pulse)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 76),
      -photonAngle * 1.5,
      math.pi / 2.5,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_OrbitalRingsPainter oldDelegate) =>
      oldDelegate.rotation != rotation || oldDelegate.pulse != pulse;
}

/// Animation durations, custom easing curves, and reusable animated wrappers
/// for AeroX AI.
///
/// Provides cubic Bézier curves, standard durations, and pre-built transition
/// widgets mirroring the web interface's micro-animations and transition states
/// from `design-system.css` and `dashboard.css`.
library;

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

bool get _isRunningInTest => !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');


/// Defines animation pacing and easing curves used across native components.
class AeroXAnimations {
  AeroXAnimations._();

  /// Snappy micro-interaction duration (150ms) for button presses and hovers.
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transition duration (300ms) for modals, drawer slides, and page fades.
  static const Duration normal = Duration(milliseconds: 300);

  /// Deliberate transition duration (500ms) for complex layout reveals.
  static const Duration slow = Duration(milliseconds: 500);

  /// Sustained animation duration (800ms) for pulsing loaders and glows.
  static const Duration slower = Duration(milliseconds: 800);

  /// Extended animation duration (1200ms) for staggered reveals.
  static const Duration extended = Duration(milliseconds: 1200);

  /// Smooth deceleration curve matching modern web styling (`cubic-bezier(0.16, 1.0, 0.3, 1.0)`).
  static const Curve easeOut = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Balanced acceleration and deceleration curve (`cubic-bezier(0.65, 0.0, 0.35, 1.0)`).
  static const Curve easeInOut = Cubic(0.65, 0.0, 0.35, 1.0);

  /// Dynamic overshoot spring curve (`cubic-bezier(0.34, 1.56, 0.64, 1.0)`).
  static const Curve easeSpring = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Gentle decelerate for subtle slide-ins.
  static const Curve gentleDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Standard page transition used across route navigations.
  static Route<T> fadeScaleRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? normal,
      reverseTransitionDuration: duration ?? normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnim = CurvedAnimation(parent: animation, curve: easeOut);
        final scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: easeSpring),
        );
        return FadeTransition(
          opacity: fadeAnim,
          child: ScaleTransition(scale: scaleAnim, child: child),
        );
      },
    );
  }

  /// Slide-up route transition matching web modal reveals.
  static Route<T> slideUpRoute<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? slow,
      reverseTransitionDuration: duration ?? normal,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: easeOut));
        final fadeAnim = CurvedAnimation(parent: animation, curve: easeOut);
        return FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(position: slideAnim, child: child),
        );
      },
    );
  }
}

/// A widget that animates its child with a staggered fade + slide-up entrance.
///
/// Used to create the sequential reveal effect seen in the web dashboard
/// where sidebar items, cards, and content sections appear one after another.
class StaggeredFadeSlide extends StatefulWidget {
  /// The index of this item in the stagger sequence (0-based).
  final int index;

  /// The child widget to animate.
  final Widget child;

  /// Base delay before the first item begins animating.
  final Duration baseDelay;

  /// Delay increment per index.
  final Duration staggerDelay;

  /// Total animation duration for each item.
  final Duration duration;

  /// Vertical offset to slide from (in pixels).
  final double slideOffset;

  /// Creates a [StaggeredFadeSlide] widget.
  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 100),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 500),
    this.slideOffset = 20.0,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeOut,
    ));

    final delay = widget.baseDelay + widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A widget that provides a subtle ambient glow pulse animation.
///
/// Matches the web dashboard's `--shadow-glow` ambient effect.
class AmbientGlow extends StatefulWidget {
  /// The child widget to wrap with a glow.
  final Widget child;

  /// The glow color (defaults to white).
  final Color glowColor;

  /// Max blur radius of the glow.
  final double maxBlurRadius;

  /// Creates an [AmbientGlow] widget.
  const AmbientGlow({
    super.key,
    required this.child,
    this.glowColor = Colors.white,
    this.maxBlurRadius = 40.0,
  });

  @override
  State<AmbientGlow> createState() => _AmbientGlowState();
}

class _AmbientGlowState extends State<AmbientGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (!_isRunningInTest) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final opacity = 0.03 + (t * 0.05);
        final blur = widget.maxBlurRadius * 0.6 + (t * widget.maxBlurRadius * 0.4);

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: opacity),
                blurRadius: blur,
                spreadRadius: blur * 0.3,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// A shimmer/sheen sweep animation widget matching the web dashboard's
/// `sheenSweep` CSS keyframe animation on hover.
class SheenSweep extends StatefulWidget {
  /// The child to overlay with a sheen effect.
  final Widget child;

  /// Whether the sheen is currently active (e.g., on hover).
  final bool isActive;

  /// Creates a [SheenSweep] widget.
  const SheenSweep({
    super.key,
    required this.child,
    this.isActive = false,
  });

  @override
  State<SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<SheenSweep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void didUpdateWidget(SheenSweep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRect(
          child: Stack(
            children: [
              widget.child,
              if (_controller.isAnimating)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sweepWidth = constraints.maxWidth * 0.6;
                      final totalTravel = constraints.maxWidth + sweepWidth * 2;
                      final left = -sweepWidth + (_controller.value * totalTravel);

                      return Transform.translate(
                        offset: Offset(left, 0),
                        child: Transform(
                          transform: Matrix4.skewX(-0.35),
                          child: Container(
                            width: sweepWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.06),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated floating particles background matching the premium web aesthetic.
class FloatingParticles extends StatefulWidget {
  /// Number of particles to render.
  final int particleCount;

  /// Creates a [FloatingParticles] widget.
  const FloatingParticles({super.key, this.particleCount = 20});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    if (!_isRunningInTest) {
      _controller.repeat();
    }

    final rng = math.Random(42);
    _particles = List.generate(widget.particleCount, (_) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.0,
        speedX: (rng.nextDouble() - 0.5) * 0.02,
        speedY: (rng.nextDouble() - 0.5) * 0.015,
        opacity: 0.03 + rng.nextDouble() * 0.07,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speedX, speedY, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = ((p.x + p.speedX * time * 50) % 1.0) * size.width;
      final y = ((p.y + p.speedY * time * 50) % 1.0) * size.height;
      final pulseOpacity = p.opacity * (0.5 + 0.5 * math.sin(time * math.pi * 2 + p.x * 10));

      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()..color = Colors.white.withValues(alpha: pulseOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

/// Animated scale-on-hover wrapper matching web `.sidebar-link:hover` and
/// `.btn:hover { transform: translateY(-1px) }` effects.
class HoverScale extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Scale factor when hovered (default 1.02).
  final double hoverScale;

  /// Vertical lift when hovered (default -1.0 pixels).
  final double hoverLift;

  /// Callback when tap occurs.
  final VoidCallback? onTap;

  /// Creates a [HoverScale] widget.
  const HoverScale({
    super.key,
    required this.child,
    this.hoverScale = 1.02,
    this.hoverLift = -1.0,
    this.onTap,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AeroXAnimations.fast,
          curve: AeroXAnimations.easeOut,
          transform: Matrix4.translationValues(0.0, _isHovered ? widget.hoverLift : 0.0, 0.0)
            ..multiply(Matrix4.diagonal3Values(
              _isPressed ? 0.97 : (_isHovered ? widget.hoverScale : 1.0),
              _isPressed ? 0.97 : (_isHovered ? widget.hoverScale : 1.0),
              1.0,
            )),
          transformAlignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

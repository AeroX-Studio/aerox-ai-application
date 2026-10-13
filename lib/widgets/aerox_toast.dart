/// Floating overlay toast notifications for transient alerts.
///
/// Features smooth spring slide-in transitions, auto-dismiss timers,
/// and semantic color framing matching the web alert toasts.
library;

import 'package:flutter/material.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';

/// Semantic classification variant for [AeroXToast].
enum AeroXToastType {
  /// Informational notice.
  info,

  /// Successful operation confirmation.
  success,

  /// Failure or validation error alert.
  error,
}

/// Utility for presenting animated floating toast alerts over the active UI.
class AeroXToast {
  /// Displays a floating overlay toast containing [message] for [duration].
  static void show(
    BuildContext context,
    String message, {
    AeroXToastType type = AeroXToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final AeroXToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AeroXAnimations.normal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeSpring,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (borderColor, iconColor, icon) = switch (widget.type) {
      AeroXToastType.success => (AeroXColors.success, AeroXColors.success, Icons.check_circle_outline),
      AeroXToastType.error => (AeroXColors.error, AeroXColors.error, Icons.error_outline),
      AeroXToastType.info => (AeroXColors.borderFocus, AeroXColors.info, Icons.info_outline),
    };

    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AeroXColors.bgElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: const [AeroXColors.shadowLg],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: iconColor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: AeroXColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

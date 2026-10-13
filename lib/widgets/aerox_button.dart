/// Interactive button component with hover states and micro-animations.
///
/// Supports multiple visual hierarchy variants, sizes, loading indicators,
/// and full-width layouts conforming to the web application styling.
library;

import 'package:flutter/material.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';

/// Visual hierarchy style for [AeroXButton].
enum AeroXButtonVariant {
  /// Solid white background with dark text for primary call-to-actions.
  primary,

  /// Transparent background with border outlines for secondary actions.
  ghost,

  /// Red accent styling for destructive operations.
  danger,
}

/// Size specification for [AeroXButton].
enum AeroXButtonSize {
  /// Compact size (padding: 6x12, font: 12).
  sm,

  /// Standard medium size (padding: 10x18, font: 14).
  md,

  /// Prominent large size (padding: 14x24, font: 16).
  lg,
}

/// An interactive button providing micro-scaling on tap and smooth hover transitions.
class AeroXButton extends StatefulWidget {
  /// The label displayed within the button.
  final String text;

  /// The callback executed when the button is tapped.
  final VoidCallback? onPressed;

  /// The visual hierarchy variant of the button.
  final AeroXButtonVariant variant;

  /// The size dimensions of the button.
  final AeroXButtonSize size;

  /// An optional leading icon.
  final Widget? icon;

  /// Whether a spinner is displayed in place of or beside the text.
  final bool isLoading;

  /// Whether the button expands to fill the available horizontal width.
  final bool isFullWidth;

  /// Creates an [AeroXButton] widget.
  const AeroXButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AeroXButtonVariant.primary,
    this.size = AeroXButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  State<AeroXButton> createState() => _AeroXButtonState();
}

class _AeroXButtonState extends State<AeroXButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (widget.variant) {
      AeroXButtonVariant.primary => (
        _isHovered ? Colors.white.withValues(alpha: 0.9) : Colors.white,
        Colors.black,
        null,
      ),
      AeroXButtonVariant.ghost => (
        _isHovered ? AeroXColors.bgHover : Colors.transparent,
        AeroXColors.textPrimary,
        Border.all(
          color: _isHovered ? AeroXColors.borderFocus : AeroXColors.borderPrimary,
          width: 1,
        ),
      ),
      AeroXButtonVariant.danger => (
        _isHovered ? AeroXColors.error.withValues(alpha: 0.2) : Colors.transparent,
        AeroXColors.error,
        Border.all(color: AeroXColors.error.withValues(alpha: 0.5), width: 1),
      ),
    };

    final (paddingV, paddingH, fontSize, radius) = switch (widget.size) {
      AeroXButtonSize.sm => (6.0, 12.0, 12.0, 6.0),
      AeroXButtonSize.md => (10.0, 18.0, 14.0, 10.0),
      AeroXButtonSize.lg => (14.0, 24.0, 16.0, 14.0),
    };

    final content = AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: AeroXAnimations.fast,
      curve: AeroXAnimations.easeOut,
      child: AnimatedContainer(
        duration: AeroXAnimations.fast,
        curve: AeroXAnimations.easeOut,
        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
        decoration: BoxDecoration(
          color: widget.onPressed == null ? bg.withValues(alpha: 0.4) : bg,
          border: border,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: _isHovered && widget.variant == AeroXButtonVariant.primary
              ? [AeroXColors.shadowMd]
              : null,
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isLoading) ...[
              SizedBox(
                width: fontSize + 2,
                height: fontSize + 2,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (widget.icon != null) ...[
              widget.icon!,
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: TextStyle(
                color: widget.onPressed == null ? fg.withValues(alpha: 0.4) : fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      cursor: widget.onPressed != null && !widget.isLoading
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: widget.isFullWidth ? SizedBox(width: double.infinity, child: content) : content,
      ),
    );
  }
}

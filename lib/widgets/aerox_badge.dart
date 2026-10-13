/// Tag, status, and chip badge component for AeroX AI.
///
/// Provides semantic styling variants matching the web application design system.
library;

import 'package:flutter/material.dart';
import '../theme/aerox_colors.dart';

/// Semantic classification variant for [AeroXBadge].
enum AeroXBadgeType {
  /// Informational status with blue accents.
  info,

  /// Positive confirmation status with green accents.
  success,

  /// Alert warning status with amber accents.
  warning,

  /// Error failure status with red accents.
  error,

  /// Neutral status with subtle monochrome accents.
  neutral,
}

/// A compact status tag displaying text and an optional leading icon.
class AeroXBadge extends StatelessWidget {
  /// The label displayed within the badge.
  final String text;

  /// The semantic color variant of the badge.
  final AeroXBadgeType type;

  /// An optional leading icon.
  final IconData? icon;

  /// Creates an [AeroXBadge] widget.
  const AeroXBadge({
    super.key,
    required this.text,
    this.type = AeroXBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (type) {
      AeroXBadgeType.info => (
        AeroXColors.info.withValues(alpha: 0.12),
        AeroXColors.info,
        AeroXColors.info.withValues(alpha: 0.25),
      ),
      AeroXBadgeType.success => (
        AeroXColors.success.withValues(alpha: 0.12),
        AeroXColors.success,
        AeroXColors.success.withValues(alpha: 0.25),
      ),
      AeroXBadgeType.warning => (
        AeroXColors.warning.withValues(alpha: 0.12),
        AeroXColors.warning,
        AeroXColors.warning.withValues(alpha: 0.25),
      ),
      AeroXBadgeType.error => (
        AeroXColors.error.withValues(alpha: 0.12),
        AeroXColors.error,
        AeroXColors.error.withValues(alpha: 0.25),
      ),
      AeroXBadgeType.neutral => (
        AeroXColors.bgElevated,
        AeroXColors.textSecondary,
        AeroXColors.borderPrimary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

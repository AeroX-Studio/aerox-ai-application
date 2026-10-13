/// Top-sliding push notification alert banner component.
///
/// Presents incoming real-time notifications with action buttons,
/// severity badges, and auto-dismiss behavior.
library;

import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import 'aerox_badge.dart';

/// Utility for presenting animated top-banner push notification alerts.
class NotificationBanner {
  /// Displays a floating top banner for the received [notification].
  static void show(
    BuildContext context,
    NotificationItem notification, {
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _NotificationBannerWidget(
        notification: notification,
        onTap: () {
          entry.remove();
          onTap?.call();
        },
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 6), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationBannerWidget({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AeroXAnimations.slow,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeSpring,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AeroXAnimations.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AeroXBadgeType badgeType = AeroXBadgeType.info;
    if (widget.notification.type == 'update') badgeType = AeroXBadgeType.success;
    if (widget.notification.type == 'promo') badgeType = AeroXBadgeType.warning;
    if (widget.notification.type == 'alert') badgeType = AeroXBadgeType.error;

    return Positioned(
      top: 24,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 540),
                decoration: BoxDecoration(
                  color: AeroXColors.bgElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AeroXColors.borderFocus, width: 1.5),
                  boxShadow: const [AeroXColors.shadowLg],
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AeroXColors.bgPrimary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AeroXColors.borderPrimary),
                          ),
                          child: const Center(
                            child: Text(
                              'AX',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'AeroX Broadcast',
                                    style: TextStyle(
                                      color: AeroXColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AeroXBadge(
                                    text: widget.notification.type.toUpperCase(),
                                    type: badgeType,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.notification.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AeroXColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AeroXColors.textTertiary),
                          onPressed: () {
                            _controller.reverse().then((_) => widget.onDismiss());
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

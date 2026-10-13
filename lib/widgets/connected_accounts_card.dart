/// Connected Accounts management card for AeroX AI native application.
///
/// Enables connecting, viewing, and disconnecting third-party OAuth providers
/// (Google) with smooth micro-animations, safety checks, and lockout prevention.
library;

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import 'aerox_badge.dart';
import 'aerox_toast.dart';

/// Interactive card managing connected third-party accounts (Google).
class ConnectedAccountsCard extends StatefulWidget {
  /// The active authenticated user.
  final User? currentUser;

  /// Callback invoked when account connection status updates.
  final VoidCallback? onAccountUpdated;

  /// Creates a [ConnectedAccountsCard] widget.
  const ConnectedAccountsCard({
    super.key,
    required this.currentUser,
    this.onAccountUpdated,
  });

  @override
  State<ConnectedAccountsCard> createState() => _ConnectedAccountsCardState();
}

class _ConnectedAccountsCardState extends State<ConnectedAccountsCard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _showSuccessBanner = false;
  String? _recentSuccessEmail;

  late AnimationController _bannerAnimController;
  late Animation<double> _bannerScaleAnim;
  late Animation<double> _bannerFadeAnim;

  @override
  void initState() {
    super.initState();
    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bannerScaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _bannerAnimController, curve: AeroXAnimations.easeSpring),
    );
    _bannerFadeAnim = CurvedAnimation(
      parent: _bannerAnimController,
      curve: AeroXAnimations.easeOut,
    );
  }

  @override
  void dispose() {
    _bannerAnimController.dispose();
    super.dispose();
  }

  void _triggerSuccessBanner(String email) {
    setState(() {
      _showSuccessBanner = true;
      _recentSuccessEmail = email;
    });
    _bannerAnimController.forward(from: 0.0);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _showSuccessBanner) {
        _bannerAnimController.reverse().then((_) {
          if (mounted) setState(() => _showSuccessBanner = false);
        });
      }
    });
  }

  Future<void> _handleConnectGoogle() async {
    setState(() => _isConnecting = true);
    try {
      final res = await _authService.linkGoogleAccountWithNative();
      if (res == null) return;
      final email = res['googleEmail']?.toString() ?? widget.currentUser?.email ?? 'Google account';
      _triggerSuccessBanner(email);
      widget.onAccountUpdated?.call();
      if (mounted) {
        AeroXToast.show(
          context,
          'Google account connected successfully',
          type: AeroXToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        if (!msg.toLowerCase().contains('cancelled') && !msg.toLowerCase().contains('canceled')) {
          AeroXToast.show(context, msg, type: AeroXToastType.error);
        }
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleDisconnect() async {
    final user = widget.currentUser;
    if (user != null && !user.hasPassword) {
      AeroXToast.show(
        context,
        'Cannot disconnect Google: Your account has no password set. Please set a password first to avoid being locked out.',
        type: AeroXToastType.error,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AeroXColors.borderPrimary),
        ),
        title: const Row(
          children: [
            Icon(Icons.link_off, color: AeroXColors.warning, size: 22),
            SizedBox(width: 10),
            Text('Disconnect Google Account?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Disconnecting Google will remove Google sign-in from your AeroX AI account. Your chats, credits, subscription, and email/password login will NOT be affected.\n\nAre you sure you want to proceed?',
          style: TextStyle(color: AeroXColors.textSecondary, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AeroXColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AeroXColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect Google'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isDisconnecting = true);
      try {
        await _authService.disconnectGoogleAccount();
        if (mounted) {
          AeroXToast.show(context, 'Google account disconnected successfully', type: AeroXToastType.success);
          widget.onAccountUpdated?.call();
        }
      } catch (e) {
        if (mounted) {
          AeroXToast.show(
            context,
            e.toString().replaceAll('Exception: ', ''),
            type: AeroXToastType.error,
          );
        }
      } finally {
        if (mounted) setState(() => _isDisconnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final isConnected = user?.isGoogleConnected ?? false;
    final googleEmail = user?.googleEmail ?? (isConnected ? user?.email : null);

    return Container(
      decoration: BoxDecoration(
        color: AeroXColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AeroXColors.borderPrimary),
        boxShadow: const [AeroXColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Success Banner
          if (_showSuccessBanner)
            FadeTransition(
              opacity: _bannerFadeAnim,
              child: ScaleTransition(
                scale: _bannerScaleAnim,
                alignment: Alignment.topCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AeroXColors.success.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AeroXColors.success.withValues(alpha: 0.3)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AeroXColors.success.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: AeroXColors.success, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Account Connected',
                              style: TextStyle(
                                color: AeroXColors.success,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_recentSuccessEmail != null)
                              Text(
                                'Connected as: $_recentSuccessEmail',
                                style: const TextStyle(color: AeroXColors.textSecondary, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AeroXColors.textSecondary),
                        onPressed: () {
                          _bannerAnimController.reverse().then((_) {
                            if (mounted) setState(() => _showSuccessBanner = false);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main Account Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Google Brand Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AeroXColors.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  child: const Center(child: _GoogleIcon(size: 20)),
                ),
                const SizedBox(width: 14),

                // Account Name & Connected Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: AeroXAnimations.normal,
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: isConnected
                                ? const AeroXBadge(
                                    key: ValueKey('connected'),
                                    text: 'Connected ✓',
                                    type: AeroXBadgeType.success,
                                  )
                                : const AeroXBadge(
                                    key: ValueKey('not_connected'),
                                    text: 'Not connected',
                                    type: AeroXBadgeType.neutral,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      AnimatedSwitcher(
                        duration: AeroXAnimations.fast,
                        child: Text(
                          isConnected && googleEmail != null
                              ? 'Connected as $googleEmail'
                              : 'Link your Google profile for seamless login',
                          key: ValueKey(isConnected ? (googleEmail ?? 'conn') : 'not-conn'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AeroXColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Connect / Disconnect Action Button
                HoverScale(
                  hoverScale: 1.03,
                  onTap: null,
                  child: isConnected
                      ? OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AeroXColors.borderPrimary),
                            foregroundColor: AeroXColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: _isDisconnecting ? null : _handleDisconnect,
                          child: _isDisconnecting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AeroXColors.error),
                                )
                              : const Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            elevation: 0,
                          ),
                          icon: _isConnecting
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                )
                              : const _GoogleIcon(size: 14),
                          label: Text(
                            _isConnecting ? 'Connecting...' : 'Connect Google',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isConnecting ? null : _handleConnectGoogle,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Official Google 'G' icon rendered with sharp vector Canvas.
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    // Google G arcs
    final rect = Rect.fromCircle(center: center, radius: radius * 0.9);

    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    // Draw top red arc
    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -2.6, 1.8, false)
      ..close();
    canvas.drawPath(pathRed, paintRed);

    // Draw yellow left arc
    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, -0.8, 1.0, false)
      ..close();
    canvas.drawPath(pathYellow, paintYellow);

    // Draw green bottom arc
    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 0.2, 1.6, false)
      ..close();
    canvas.drawPath(pathGreen, paintGreen);

    // Draw blue right bar and arc
    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, 1.8, 1.8, false)
      ..close();
    canvas.drawPath(pathBlue, paintBlue);

    // Cut out inner circle to make ring
    final innerPaint = Paint()
      ..color = AeroXColors.bgElevated
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.52, innerPaint);

    // Draw blue crossbar
    final barRect = Rect.fromLTWH(center.dx - radius * 0.05, center.dy - radius * 0.22, radius * 0.95, radius * 0.44);
    canvas.drawRect(barRect, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

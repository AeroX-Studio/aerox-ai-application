/// Cross-platform announcement presentation dialog.
///
/// Renders rich modal announcements across Windows, Android, iOS,
/// macOS, and Linux applications with cover images, video media,
/// dynamic accent colors, action buttons, and automatic telemetry reporting.
/// Matches design language and visual parity with Screenshot 2026-09-25 111551.png.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/announcement_item.dart';
import '../services/announcement_service.dart';

/// Modal dialog presenting a published announcement to the user with
/// professional entrance animations and media support.
class AnnouncementDialog extends StatefulWidget {
  final AnnouncementItem announcement;
  final Function(String modelId)? onModelSelect;

  const AnnouncementDialog({
    super.key,
    required this.announcement,
    this.onModelSelect,
  });

  /// Helper to display this dialog over the current navigator.
  static Future<void> show(
    BuildContext context,
    AnnouncementItem announcement, {
    Function(String modelId)? onModelSelect,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => AnnouncementDialog(
        announcement: announcement,
        onModelSelect: onModelSelect,
      ),
    );
  }

  @override
  State<AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<AnnouncementDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _bellAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _bellAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.06), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.03), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    try {
      final hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty || url == '#') return;
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }

  void _handleButtonAction(AnnouncementButton btn, int index) async {
    AnnouncementService().recordClick(widget.announcement.id, buttonIndex: index);
    AnnouncementService().dismiss(widget.announcement.id);
    if (!mounted) return;
    Navigator.of(context).pop();

    // Check if the URL indicates an in-app model selection: e.g. /chat?model=xxx
    final uri = Uri.tryParse(btn.url);
    if (uri != null && uri.queryParameters.containsKey('model')) {
      final modelId = uri.queryParameters['model'];
      if (modelId != null && modelId.isNotEmpty && widget.onModelSelect != null) {
        widget.onModelSelect!(modelId);
        return;
      }
    }

    if (btn.url.startsWith('http://') || btn.url.startsWith('https://')) {
      await _launchUrl(btn.url);
    }
  }

  List<String> _extractFeatureBullets(String raw) {
    final clean = raw
        .replaceAll(RegExp(r'<p>|</p>|<strong>|</strong>|<em>|</em>'), '')
        .trim();

    if (clean.contains('<li>')) {
      final matches = RegExp(r'<li>(.*?)</li>', dotAll: true).allMatches(clean);
      return matches
          .map((m) => m.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Split on bullet markers or newlines
    final lines = clean.split(RegExp(r'[\r\n]+'));
    final bullets = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*')) {
        bullets.add(trimmed.substring(1).trim());
      }
    }
    return bullets;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _parseColor(widget.announcement.accentColor, const Color(0xFF6366F1));
    final buttonColor = _parseColor(widget.announcement.buttonColor, const Color(0xFF5B63F6));
    final textColor = _parseColor(widget.announcement.textColor, Colors.white);

    final hasVideo = widget.announcement.videoUrl != null &&
        widget.announcement.videoUrl!.isNotEmpty &&
        widget.announcement.mediaType != 'none';

    final hasImage = widget.announcement.coverImage != null &&
        widget.announcement.coverImage!.isNotEmpty &&
        widget.announcement.mediaType != 'none' &&
        !hasVideo;

    final typeLabel = widget.announcement.type.replaceAll('_', ' ').toUpperCase();
    final rawBody = widget.announcement.content ?? widget.announcement.shortDescription ?? '';
    final bullets = _extractFeatureBullets(rawBody);

    final primaryBtn = widget.announcement.buttons.isNotEmpty
        ? widget.announcement.buttons.first
        : AnnouncementButton(text: 'Learn More', url: '#');

    final secondaryBtn = widget.announcement.buttons.length > 1
        ? widget.announcement.buttons[1]
        : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1017),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Bell Icon + Outlined Pill Badge + Close 'X'
                    Row(
                      children: [
                        // Animated Outline Bell Icon matching reference
                        RotationTransition(
                          turns: _bellAnimation,
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 23,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Outlined Pill Badge with accent border (NEW MODEL, UPDATE, etc.)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accentColor, width: 1.2),
                          ),
                          child: Text(
                            typeLabel.isNotEmpty ? typeLabel : 'NEW MODEL',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Subtle Minimal Close Button 'X'
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              AnnouncementService().dismiss(widget.announcement.id);
                              Navigator.of(context).pop();
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Media Attachment (Video or Image if assigned)
                    if (hasVideo) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 170,
                          decoration: BoxDecoration(
                            color: const Color(0xFF090A0F),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (widget.announcement.coverImage != null &&
                                  widget.announcement.coverImage!.isNotEmpty)
                                Image.network(
                                  widget.announcement.coverImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                )
                              else
                                Container(
                                  color: Colors.black87,
                                  child: Icon(
                                    Icons.videocam_rounded,
                                    size: 44,
                                    color: accentColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              Center(
                                child: Material(
                                  color: accentColor,
                                  shape: const CircleBorder(),
                                  elevation: 6,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => _launchUrl(widget.announcement.videoUrl!),
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.ondemand_video, size: 11, color: Colors.white70),
                                      SizedBox(width: 4),
                                      Text(
                                        'VIDEO',
                                        style: TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (hasImage) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 170,
                          decoration: BoxDecoration(
                            color: const Color(0xFF090A0F),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(
                            widget.announcement.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Announcement Title (Bold White)
                    Text(
                      widget.announcement.title,
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Subtitle / Intro
                    if (widget.announcement.subtitle != null &&
                        widget.announcement.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.announcement.subtitle!,
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Feature Bullets or Content Body
                    if (bullets.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bullets.take(4).map((b) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 3, right: 9),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check, size: 9, color: accentColor),
                                ),
                                Expanded(
                                  child: Text(
                                    b,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 13,
                                      color: const Color(0xFF94A3B8),
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: SingleChildScrollView(
                          child: Text(
                            rawBody.replaceAll(RegExp(r'<[^>]*>'), ''),
                            style: GoogleFonts.quicksand(
                              fontSize: 13.5,
                              color: const Color(0xFF94A3B8),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    // Full-Width Primary CTA Button matching reference
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          shadowColor: buttonColor.withValues(alpha: 0.45),
                        ),
                        onPressed: () => _handleButtonAction(primaryBtn, 0),
                        child: Text(
                          primaryBtn.text.isNotEmpty ? primaryBtn.text : 'Learn More',
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    // Optional Secondary Button
                    if (secondaryBtn != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _handleButtonAction(secondaryBtn, 1),
                          child: Text(
                            secondaryBtn.text,
                            style: GoogleFonts.quicksand(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

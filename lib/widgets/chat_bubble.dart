/// Chat message presentation widget with markdown and code formatting.
///
/// Handles user prompts, assistant streaming outputs, multi-modal image
/// previews, copy actions, and pulsing thinking indicators.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import 'aerox_toast.dart';

/// Renders an individual [ChatMessage] bubble for either user or assistant.
class ChatBubble extends StatelessWidget {
  /// The [ChatMessage] payload to render.
  final ChatMessage message;

  /// The optional AI model name displayed above assistant responses.
  final String? modelName;

  /// Optional callback to retry failed generation.
  final VoidCallback? onRetry;

  /// Optional callback to regenerate the assistant response.
  final VoidCallback? onRegenerate;

  /// Creates a [ChatBubble] widget.
  const ChatBubble({
    super.key,
    required this.message,
    this.modelName,
    this.onRetry,
    this.onRegenerate,
  });

  String _resolveImageUrl(String src) {
    if (src.startsWith('http://') || src.startsWith('https://')) {
      return src;
    }
    final base = ApiService().effectiveBaseUrl;
    final path = src.startsWith('/') ? src : '/$src';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    }
    return _buildAssistantBubble(context);
  }

  Widget _buildUserBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 680),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AeroXColors.bgElevated,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                border: Border.all(color: AeroXColors.borderPrimary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachments previews if any
                  if (message.attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.attachments.map((att) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AeroXColors.bgPrimary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AeroXColors.borderPrimary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                att.isImage
                                    ? Icons.image
                                    : (att.isAudio ? Icons.graphic_eq_rounded : Icons.attach_file),
                                size: 14,
                                color: att.isAudio ? AeroXColors.accent : AeroXColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                att.isAudio ? 'Voice Message' : att.originalName,
                                style: TextStyle(
                                  color: att.isAudio ? Colors.white : AeroXColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: att.isAudio ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SelectableText(
                    message.content,
                    style: AeroXTheme.body(
                      color: AeroXColors.textPrimary,
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // User Avatar (matches v2 .message-user .message-avatar)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AeroXColors.bgSurface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AeroXColors.borderPrimary),
            ),
            child: const Center(
              child: Text(
                'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant Avatar (Official AeroX AI Emblem matching v2)
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.only(top: 2, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Image.asset(
                  'assets/images/logo_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Model name header matching v2 .message-role
                Row(
                  children: [
                    Text(
                      (modelName ?? 'AeroX AI').toUpperCase(),
                      style: AeroXTheme.tech(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AeroXColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    if (message.isStreaming) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AeroXColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Generating...',
                        style: AeroXTheme.tech(
                          color: AeroXColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Markdown Renderer matching v2 .message-text
                MarkdownBody(
                  data: message.content.isEmpty && message.isStreaming
                      ? 'Thinking...'
                      : message.content,
                  // ignore: deprecated_member_use
                  imageBuilder: (uri, title, alt) {
                    final resolved = _resolveImageUrl(uri.toString());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          resolved,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 200,
                              color: AeroXColors.bgCard,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 100,
                            color: AeroXColors.bgCard,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: AeroXColors.textTertiary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: AeroXTheme.body(
                      fontSize: 14.5,
                      height: 1.7,
                      color: const Color(0xFFD1D5DB),
                    ),
                    code: AeroXTheme.mono(
                      fontSize: 13,
                      color: AeroXColors.textPrimary,
                    ).copyWith(
                      backgroundColor: AeroXColors.bgInput,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AeroXColors.bgSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AeroXColors.borderPrimary),
                    ),
                    codeblockPadding: const EdgeInsets.all(14),
                    h1: AeroXTheme.heading(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h2: AeroXTheme.heading(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h3: AeroXTheme.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    h4: AeroXTheme.heading(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    blockquote: AeroXTheme.body(
                      fontSize: 14,
                      color: const Color(0xFFCBD5E1),
                      height: 1.6,
                    ).copyWith(fontStyle: FontStyle.italic),
                    blockquoteDecoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF444444), width: 3),
                      ),
                    ),
                    listBullet: const TextStyle(color: AeroXColors.textSecondary),
                    tableBorder: TableBorder.all(color: AeroXColors.borderPrimary, width: 1),
                    tableHead: AeroXTheme.tech(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    tableBody: AeroXTheme.body(
                      fontSize: 13.5,
                      color: const Color(0xFFD1D5DB),
                    ),
                  ),
                ),

                // Typing blinking cursor if streaming
                if (message.isStreaming) ...[
                  const SizedBox(height: 4),
                  const _BlinkingCursor(),
                ],

                // Action buttons below assistant message
                if (!message.isStreaming && (message.content.isNotEmpty || message.isError)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (message.content.isNotEmpty) ...[
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: message.content));
                            AeroXToast.show(context, 'Copied response to clipboard', type: AeroXToastType.success);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.copy, size: 12, color: AeroXColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: AeroXColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (message.isError && onRetry != null) ...[
                        InkWell(
                          onTap: onRetry,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.refresh, size: 12, color: AeroXColors.warning),
                                SizedBox(width: 4),
                                Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: AeroXColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else if (!message.isError && onRegenerate != null) ...[
                        InkWell(
                          onTap: onRegenerate,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.refresh, size: 12, color: AeroXColors.textTertiary),
                                SizedBox(width: 4),
                                Text(
                                  'Regenerate',
                                  style: TextStyle(
                                    color: AeroXColors.textTertiary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (message.tokenCount != null && message.tokenCount! > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${message.tokenCount} tokens',
                          style: const TextStyle(
                            color: AeroXColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 16,
        color: Colors.white,
      ),
    );
  }
}

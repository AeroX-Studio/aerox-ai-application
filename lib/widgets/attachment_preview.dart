/// Attachment tray widget displaying staged images and files before transmission.
///
/// Features file thumbnail previews, byte size badges, linear upload progress bars,
/// and removal action buttons.
library;

import 'package:flutter/material.dart';
import '../models/attachment_item.dart';
import '../theme/aerox_colors.dart';

/// A horizontal scrollable bar displaying pending attachments and upload progress.
class AttachmentPreviewTray extends StatelessWidget {
  /// The list of staged [AttachmentItem] objects.
  final List<AttachmentItem> attachments;

  /// Callback executed when the remove button on an item is tapped.
  final Function(int index) onRemove;

  /// Creates an [AttachmentPreviewTray] widget.
  const AttachmentPreviewTray({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AeroXColors.bgSecondary,
        border: Border(top: BorderSide(color: AeroXColors.borderPrimary)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = attachments[index];
          return Container(
            width: 190,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AeroXColors.bgElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AeroXColors.borderPrimary),
            ),
            child: Row(
              children: [
                // Thumbnail or Document icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 42,
                    height: 42,
                    color: AeroXColors.bgPrimary,
                    child: item.bytes != null && item.isImage
                        ? Image.memory(item.bytes!, fit: BoxFit.cover)
                        : Icon(
                            item.isImage ? Icons.image : Icons.insert_drive_file,
                            size: 20,
                            color: AeroXColors.textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.originalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AeroXColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (item.isUploading) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.progress > 0 ? item.progress : null,
                            minHeight: 4,
                            backgroundColor: AeroXColors.bgInput,
                            valueColor: const AlwaysStoppedAnimation<Color>(AeroXColors.textPrimary),
                          ),
                        ),
                      ] else ...[
                        Text(
                          _formatSize(item.size),
                          style: const TextStyle(
                            color: AeroXColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 14, color: AeroXColors.textTertiary),
                  onPressed: () => onRemove(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

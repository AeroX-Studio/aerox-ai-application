/// Model representing user attachments, camera captures, and uploaded files.
///
/// Encapsulates multi-modal media properties, byte streams, and reactive
/// upload progress states.
library;

import 'dart:typed_data';

/// Represents a media file or document attached to a chat conversation.
class AttachmentItem {
  /// The server-assigned storage identifier if already uploaded.
  final String? id;

  /// The stored filename on the backend storage system.
  final String filename;

  /// The original human-readable filename when selected by the user.
  final String originalName;

  /// The MIME content type of the file (e.g. `'image/png'`, `'application/pdf'`).
  final String mimeType;

  /// The total size of the file in bytes.
  final int size;

  /// The public download or preview URL of the uploaded file.
  final String? url;

  /// In-memory binary contents used for immediate preview and camera snaps.
  final Uint8List? bytes;

  /// The absolute local filesystem path on desktop and mobile platforms.
  final String? localPath;

  /// Whether the file is currently being transferred to the backend.
  bool isUploading;

  /// The upload progress ratio ranging from `0.0` to `1.0`.
  double progress;

  /// Creates a new [AttachmentItem] with given media attributes.
  AttachmentItem({
    this.id,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.size,
    this.url,
    this.bytes,
    this.localPath,
    this.isUploading = false,
    this.progress = 0.0,
  });

  /// Whether this attachment represents an image format suitable for inline display.
  bool get isImage =>
      mimeType.startsWith('image/') ||
      filename.toLowerCase().endsWith('.png') ||
      filename.toLowerCase().endsWith('.jpg') ||
      filename.toLowerCase().endsWith('.jpeg') ||
      filename.toLowerCase().endsWith('.webp') ||
      filename.toLowerCase().endsWith('.gif');

  /// Whether this attachment represents an audio recording or voice message.
  bool get isAudio =>
      mimeType.startsWith('audio/') ||
      filename.toLowerCase().endsWith('.m4a') ||
      filename.toLowerCase().endsWith('.aac') ||
      filename.toLowerCase().endsWith('.mp3') ||
      filename.toLowerCase().endsWith('.wav') ||
      filename.toLowerCase().endsWith('.ogg');

  /// Deserializes an [AttachmentItem] from a JSON map.
  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: json['id']?.toString(),
      filename: json['filename']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? json['filename']?.toString() ?? 'Attachment',
      mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
      size: (json['size'] as num?)?.toInt() ?? 0,
      url: json['url']?.toString(),
    );
  }

  /// Serializes the attachment metadata into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'originalName': originalName,
      'mimeType': mimeType,
      'size': size,
      'url': url,
    };
  }
}

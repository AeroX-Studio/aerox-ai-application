/// File management, camera acquisition, and upload transfer service.
///
/// Coordinates cross-platform file picking, device camera capture,
/// size constraints verification, and multipart HTTP uploads.
library;

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment_item.dart';
import 'api_service.dart';

/// Service managing device media capture, local file selection, and remote uploads.
class FileService {
  static final FileService _instance = FileService._internal();

  /// Returns the shared singleton instance of [FileService].
  factory FileService() => _instance;
  FileService._internal();

  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  /// Maximum permissible file upload size in bytes (10 Megabytes).
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Captures a photograph using the device camera.
  ///
  /// Returns an [AttachmentItem] with image bytes, or `null` if canceled.
  Future<AttachmentItem?> captureFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (photo == null) return null;

      final bytes = await photo.readAsBytes();
      if (bytes.lengthInBytes > maxFileSizeBytes) {
        throw Exception('Image size exceeds 10MB limit. Please capture a smaller photo.');
      }

      return AttachmentItem(
        filename: photo.name,
        originalName: photo.name,
        mimeType: photo.mimeType ?? 'image/jpeg',
        size: bytes.lengthInBytes,
        bytes: bytes,
        localPath: photo.path,
      );
    } catch (e) {
      throw Exception('Camera capture error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// Opens the device photo library or gallery to select a single picture.
  Future<AttachmentItem?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > maxFileSizeBytes) {
        throw Exception('Image size exceeds 10MB limit.');
      }

      return AttachmentItem(
        filename: image.name,
        originalName: image.name,
        mimeType: image.mimeType ?? 'image/jpeg',
        size: bytes.lengthInBytes,
        bytes: bytes,
        localPath: image.path,
      );
    } catch (e) {
      throw Exception('Image selection error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// Opens a native system file dialog to pick one or more documents or media files.
  ///
  /// Works across Windows, Android, iOS, macOS, and Linux platforms.
  Future<List<AttachmentItem>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'pdf', 'txt', 'md', 'json', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final items = <AttachmentItem>[];
      for (final file in result.files) {
        final size = file.size;
        if (size > maxFileSizeBytes) {
          throw Exception('File "${file.name}" exceeds 10MB limit.');
        }

        final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);

        String mime = 'application/octet-stream';
        final ext = (file.extension ?? '').toLowerCase();
        if (ext == 'png') mime = 'image/png';
        if (ext == 'jpg' || ext == 'jpeg') mime = 'image/jpeg';
        if (ext == 'webp') mime = 'image/webp';
        if (ext == 'gif') mime = 'image/gif';
        if (ext == 'pdf') mime = 'application/pdf';
        if (ext == 'txt' || ext == 'md') mime = 'text/plain';

        items.add(AttachmentItem(
          filename: file.name,
          originalName: file.name,
          mimeType: mime,
          size: size,
          bytes: bytes,
          localPath: file.path,
        ));
      }

      return items;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Uploads the given [item] to the backend server with optional [onProgress] reporting.
  Future<AttachmentItem> uploadAttachment(
    AttachmentItem item, {
    Function(double progress)? onProgress,
  }) async {
    item.isUploading = true;
    item.progress = 0.1;
    onProgress?.call(0.1);

    try {
      final uri = Uri.parse('${_api.effectiveBaseUrl}/api/files/upload');
      final request = http.MultipartRequest('POST', uri);

      request.headers['x-app-client'] = 'aerox-native';
      if (_api.sessionCookie != null && _api.sessionCookie!.isNotEmpty) {
        request.headers['Cookie'] = _api.sessionCookie!;
      }
      if (_api.sessionToken != null && _api.sessionToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${_api.sessionToken}';
        request.headers['x-session-token'] = _api.sessionToken!;
      }

      MediaType contentType;
      try {
        contentType = MediaType.parse(item.mimeType);
      } catch (_) {
        final ext = (item.filename.split('.').lastOrNull ?? '').toLowerCase();
        if (ext == 'png') {
          contentType = MediaType('image', 'png');
        } else if (ext == 'webp') {
          contentType = MediaType('image', 'webp');
        } else if (ext == 'gif') {
          contentType = MediaType('image', 'gif');
        } else {
          contentType = MediaType('image', 'jpeg');
        }
      }

      if (item.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          item.bytes!,
          filename: item.filename,
          contentType: contentType,
        ));
      } else if (item.localPath != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          item.localPath!,
          filename: item.filename,
          contentType: contentType,
        ));
      } else {
        throw Exception('No file data available for upload');
      }

      item.progress = 0.5;
      onProgress?.call(0.5);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        item.isUploading = false;
        item.progress = 1.0;
        onProgress?.call(1.0);

        return AttachmentItem(
          id: data['id']?.toString(),
          filename: data['filename']?.toString() ?? item.filename,
          originalName: data['originalName']?.toString() ?? item.originalName,
          mimeType: data['mimeType']?.toString() ?? item.mimeType,
          size: (data['size'] as num?)?.toInt() ?? item.size,
          url: data['url']?.toString(),
          bytes: item.bytes,
          localPath: item.localPath,
        );
      }

      final errorMsg = response.body.isNotEmpty ? response.body : 'Upload failed (${response.statusCode})';
      throw Exception(errorMsg);
    } catch (e) {
      item.isUploading = false;
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

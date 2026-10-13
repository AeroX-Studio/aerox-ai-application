/// Platform detection, device telemetry, and version check service.
///
/// Discovers client runtime environments (Windows, Android, iOS, macOS, Linux),
/// assigns persistent installation device IDs, and queries platform maintenance modes.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/platform_config.dart';
import 'api_service.dart';

/// Service managing device telemetry, platform diagnostics, and version verification.
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();

  /// Returns the shared singleton instance of [PlatformService].
  factory PlatformService() => _instance;
  PlatformService._internal();

  final ApiService _api = ApiService();
  String? _deviceId;

  /// The active operating system identifier (e.g. `'windows'`, `'android'`, `'ios'`, `'macos'`, `'linux'`).
  String get currentPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// The human-readable operating system kernel or build version string.
  String get currentOsVersion {
    if (kIsWeb) return 'Web Browser';
    return Platform.operatingSystemVersion;
  }

  /// Retrieves or generates a unique, persistent client installation identifier.
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('aerox_device_id');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString('aerox_device_id', id);
    }
    _deviceId = id;
    return id;
  }

  /// Queries the central backend for platform version constraints and maintenance flags.
  Future<PlatformConfig?> checkPlatformStatus() async {
    try {
      final res = await _api.get('/api/app/config?platform=$currentPlatform');
      if (res is Map<String, dynamic> && res['platform'] != null) {
        return PlatformConfig.fromJson(res['platform'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Registers the device session and hardware telemetry with the Admin Panel.
  Future<void> registerDeviceSession({String? userId}) async {
    try {
      final deviceId = await getDeviceId();
      await _api.post('/api/app/device/register', {
        'deviceId': deviceId,
        'platform': currentPlatform,
        'appVersion': '1.0.0',
        'osVersion': currentOsVersion,
        'deviceModel': kIsWeb ? 'Web Client' : Platform.localHostname,
      });
    } catch (_) {}
  }
}

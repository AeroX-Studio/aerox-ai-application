/// Model representing platform release configuration and maintenance status.
///
/// Encapsulates version compatibility constraints, download links, and
/// live maintenance alerts managed from the Admin Panel.
library;

/// Configuration parameters for a specific client platform target.
class PlatformConfig {
  /// The platform slug (e.g. `'windows'`, `'android'`, `'ios'`, `'macos'`, `'linux'`).
  final String platform;

  /// The human-readable name of the platform (e.g. `'Windows Desktop'`).
  final String name;

  /// The latest production release version string (e.g. `'1.0.0'`).
  final String latestVersion;

  /// The minimum client version required before forced upgrade prompts trigger.
  final String minSupportedVersion;

  /// The download or store URL for obtaining the latest release.
  final String? downloadUrl;

  /// Changelog and release summary notes for this build.
  final String? releaseNotes;

  /// Whether the platform target is currently locked for maintenance.
  final bool isMaintenance;

  /// The broadcast explanation shown to users when maintenance is active.
  final String? maintenanceMessage;

  /// Creates a new [PlatformConfig] instance.
  PlatformConfig({
    required this.platform,
    required this.name,
    this.latestVersion = '1.0.0',
    this.minSupportedVersion = '1.0.0',
    this.downloadUrl,
    this.releaseNotes,
    this.isMaintenance = false,
    this.maintenanceMessage,
  });

  /// Deserializes a [PlatformConfig] from a JSON map.
  factory PlatformConfig.fromJson(Map<String, dynamic> json) {
    return PlatformConfig(
      platform: json['platform']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      minSupportedVersion: json['minSupportedVersion']?.toString() ?? '1.0.0',
      downloadUrl: json['downloadUrl']?.toString(),
      releaseNotes: json['releaseNotes']?.toString(),
      isMaintenance: json['isMaintenance'] == true,
      maintenanceMessage: json['maintenanceMessage']?.toString(),
    );
  }
}

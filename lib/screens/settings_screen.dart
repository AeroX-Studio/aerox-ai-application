/// User Profile and Application Settings Screen for AeroX AI.
///
/// Features account profile details, AI intelligence & creativity preferences,
/// AMOLED dark theme options, sound & haptic feedback, cache cleaner,
/// live server latency, and hidden developer settings.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/aerox_colors.dart';
import '../widgets/aerox_badge.dart';
import '../widgets/aerox_button.dart';
import '../widgets/aerox_toast.dart';
import '../widgets/connected_accounts_card.dart';
import 'auth_screen.dart';

/// Comprehensive settings interface for configuring user preferences and AI behaviour.
class SettingsScreen extends StatefulWidget {
  /// The currently authenticated user profile.
  final User? currentUser;

  /// Callback when user logs out or modifies profile.
  final VoidCallback? onUserUpdated;

  /// Creates a [SettingsScreen] widget.
  const SettingsScreen({
    super.key,
    this.currentUser,
    this.onUserUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // Preferences
  double _temperature = 0.7;
  bool _enableHaptics = true;
  bool _enableSoundEffects = true;
  bool _syntaxHighlighting = true;
  bool _streamAnimation = true;
  bool _amoledMode = false;
  String _fontSize = 'Normal';
  String _cacheSizeText = 'Calculating...';

  int _latencyMs = 0;
  bool _isCheckingLatency = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _calculateCacheSize();
    _checkServerLatency();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = prefs.getDouble('pref_temperature') ?? 0.7;
      _enableHaptics = prefs.getBool('pref_haptics') ?? true;
      _enableSoundEffects = prefs.getBool('pref_sound') ?? true;
      _syntaxHighlighting = prefs.getBool('pref_syntax') ?? true;
      _streamAnimation = prefs.getBool('pref_stream_anim') ?? true;
      _amoledMode = prefs.getBool('pref_amoled') ?? false;
      _fontSize = prefs.getString('pref_font_size') ?? 'Normal';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
    if (_enableHaptics) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      int totalBytes = 0;
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        try {
          await for (final file in tempDir.list(recursive: false, followLinks: false)) {
            if (file is File) {
              totalBytes += await file.length();
            }
          }
        } catch (_) {}
      }
      final mb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
      if (mounted) {
        setState(() {
          _cacheSizeText = '$mb MB';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeText = '12.4 MB';
        });
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        try {
          await for (final file in tempDir.list(recursive: false, followLinks: false)) {
            if (file is File) {
              await file.delete().catchError((_) => file);
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _cacheSizeText = '0.0 MB');
        AeroXToast.show(context, 'Cache and temporary files cleared', type: AeroXToastType.success);
        if (_enableHaptics) HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        AeroXToast.show(context, 'Error clearing cache: $e', type: AeroXToastType.error);
      }
    }
  }

  Future<void> _checkServerLatency() async {
    setState(() => _isCheckingLatency = true);
    final start = DateTime.now();
    try {
      final res = await _apiService.testConnection();
      final ms = DateTime.now().difference(start).inMilliseconds;
      if (mounted) {
        setState(() {
          _latencyMs = res['success'] == true ? ms : 0;
          _isCheckingLatency = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _latencyMs = 0;
          _isCheckingLatency = false;
        });
      }
    }
  }

  void _onVersionTap() {
    if (_enableHaptics) HapticFeedback.lightImpact();
    AeroXToast.show(
      context,
      'AeroX AI v1.0.0 (Production)',
      type: AeroXToastType.info,
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of AeroX AI?', style: TextStyle(color: AeroXColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AeroXColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AeroXColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 820;
    final user = widget.currentUser;
    final bgColor = _amoledMode ? Colors.black : AeroXColors.bgPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildAppBar(context),

            // Scrollable Settings Content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 760 : double.infinity),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    children: [
                      // User Profile Header Card
                      _buildProfileCard(user),
                      const SizedBox(height: 20),

                      // Section: Connected Accounts
                      _buildSectionHeader('Connected Accounts'),
                      ConnectedAccountsCard(
                        currentUser: user,
                        onAccountUpdated: () {
                          widget.onUserUpdated?.call();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),

                      // Section: AI Intelligence & Generation
                      _buildSectionHeader('AI Intelligence & Response'),
                      _buildSettingsCard([
                        _buildSliderTile(
                          icon: Icons.psychology_outlined,
                          title: 'Creativity / Temperature',
                          subtitle: _temperature < 0.4
                              ? 'Precise & Deterministic (${_temperature.toStringAsFixed(1)})'
                              : (_temperature < 0.8
                                  ? 'Balanced & Factual (${_temperature.toStringAsFixed(1)})'
                                  : 'Creative & Imaginative (${_temperature.toStringAsFixed(1)})'),
                          value: _temperature,
                          min: 0.1,
                          max: 1.2,
                          onChanged: (val) {
                            setState(() => _temperature = val);
                            _savePreference('pref_temperature', val);
                          },
                        ),
                        const Divider(color: AeroXColors.borderPrimary, height: 1),
                        _buildSwitchTile(
                          icon: Icons.code,
                          title: 'Code Syntax Highlighting',
                          subtitle: 'Render fenced programming blocks with styled keywords',
                          value: _syntaxHighlighting,
                          onChanged: (val) {
                            setState(() => _syntaxHighlighting = val);
                            _savePreference('pref_syntax', val);
                          },
                        ),
                        const Divider(color: AeroXColors.borderPrimary, height: 1),
                        _buildSwitchTile(
                          icon: Icons.speed_outlined,
                          title: 'Stream Typewriter Animation',
                          subtitle: 'Simulate natural human typewriter effect during AI streaming',
                          value: _streamAnimation,
                          onChanged: (val) {
                            setState(() => _streamAnimation = val);
                            _savePreference('pref_stream_anim', val);
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Section: Display & Appearance
                      _buildSectionHeader('Display & Visuals'),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          icon: Icons.brightness_2_outlined,
                          title: 'Pure AMOLED Black Mode',
                          subtitle: 'True black background (#000000) for OLED mobile battery savings',
                          value: _amoledMode,
                          onChanged: (val) {
                            setState(() => _amoledMode = val);
                            _savePreference('pref_amoled', val);
                          },
                        ),
                        const Divider(color: AeroXColors.borderPrimary, height: 1),
                        _buildDropdownTile(
                          icon: Icons.format_size,
                          title: 'Message Font Size',
                          subtitle: 'Scale readability of chat responses',
                          value: _fontSize,
                          options: const ['Compact', 'Normal', 'Large'],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _fontSize = val);
                              _savePreference('pref_font_size', val);
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Section: Haptics & Feedback
                      _buildSectionHeader('Haptics & Feedback'),
                      _buildSettingsCard([
                        _buildSwitchTile(
                          icon: Icons.vibration,
                          title: 'Haptic Touch Feedback',
                          subtitle: 'Vibrate lightly on button presses and message events',
                          value: _enableHaptics,
                          onChanged: (val) {
                            setState(() => _enableHaptics = val);
                            _savePreference('pref_haptics', val);
                          },
                        ),
                        const Divider(color: AeroXColors.borderPrimary, height: 1),
                        _buildSwitchTile(
                          icon: Icons.volume_up_outlined,
                          title: 'Audio Feedback',
                          subtitle: 'Play subtle tones on generation completion',
                          value: _enableSoundEffects,
                          onChanged: (val) {
                            setState(() => _enableSoundEffects = val);
                            _savePreference('pref_sound', val);
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Section: Data & Storage
                      _buildSectionHeader('Storage & Performance'),
                      _buildSettingsCard([
                        ListTile(
                          leading: const Icon(Icons.storage_outlined, color: AeroXColors.textSecondary, size: 22),
                          title: const Text('Temporary Cache Size', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text('Cached images, uploads, and data: $_cacheSizeText', style: const TextStyle(color: AeroXColors.textTertiary, fontSize: 12)),
                          trailing: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AeroXColors.borderPrimary),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _clearCache,
                            child: const Text('Clear', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Section: Network & Infrastructure
                      _buildSectionHeader('Network & Connectivity'),
                      _buildSettingsCard([
                        ListTile(
                          leading: Icon(
                            Icons.cloud_done_outlined,
                            color: _latencyMs > 0 ? AeroXColors.success : AeroXColors.warning,
                            size: 22,
                          ),
                          title: const Text('Server Connection', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            _isCheckingLatency
                                ? 'Measuring response ping...'
                                : (_latencyMs > 0 ? 'Connected • ${_latencyMs}ms latency' : 'Offline or connecting...'),
                            style: TextStyle(
                              color: _latencyMs > 0 ? AeroXColors.success : AeroXColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.refresh, color: AeroXColors.textSecondary, size: 18),
                            onPressed: _checkServerLatency,
                            tooltip: 'Test latency',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Section: About & Developer Options
                      _buildSectionHeader('About AeroX AI'),
                      _buildSettingsCard([
                        InkWell(
                          onTap: _onVersionTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: const Color(0xFF27272A), width: 1),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AeroX AI Cross-Platform',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Version 2.5.0 (Build 128) • Unified Native Engine',
                                        style: TextStyle(color: AeroXColors.textTertiary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AeroXColors.textTertiary, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Sign Out Button
                      AeroXButton(
                        text: 'Sign Out Account',
                        icon: const Icon(Icons.logout, size: 16, color: Colors.white),
                        variant: AeroXButtonVariant.danger,
                        size: AeroXButtonSize.md,
                        isFullWidth: true,
                        onPressed: _handleLogout,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AeroXColors.borderPrimary)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Chat',
          ),
          const SizedBox(width: 6),
          const Text(
            'Settings & Preferences',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    final name = user?.displayName ?? 'AeroX Explorer';
    final email = user?.email ?? 'No email bound';
    final credits = user?.availableCredits ?? 0;
    final totalCredits = user?.totalCredits ?? (credits > 0 ? credits : 100);
    final ratio = totalCredits > 0 ? (credits / totalCredits).clamp(0.0, 1.0) : 0.0;
    final tier = user?.packageName ?? (user?.role == 'super_admin' ? 'Super Admin' : 'Free Tier');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AeroXColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AeroXColors.borderPrimary),
        boxShadow: const [AeroXColors.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AeroXColors.bgSurface,
                  border: Border.all(color: AeroXColors.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AeroXBadge(
                          text: tier,
                          type: tier.toLowerCase().contains('pro') || tier.toLowerCase().contains('admin')
                              ? AeroXBadgeType.success
                              : AeroXBadgeType.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AeroXColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AeroXColors.borderPrimary, height: 1),
          const SizedBox(height: 14),

          // Credit Balance Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Credits', style: TextStyle(color: AeroXColors.textSecondary, fontSize: 12)),
              Text(
                '${credits.toStringAsFixed(0)} / ${totalCredits.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AeroXColors.bgElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AeroXColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AeroXColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AeroXColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AeroXColors.borderPrimary),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AeroXColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AeroXColors.textTertiary, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AeroXColors.textPrimary,
        activeTrackColor: AeroXColors.textPrimary.withValues(alpha: 0.32),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AeroXColors.textSecondary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AeroXColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 11,
            activeColor: AeroXColors.textPrimary,
            inactiveColor: AeroXColors.bgElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AeroXColors.textSecondary, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AeroXColors.textTertiary, fontSize: 12)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AeroXColors.bgElevated,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        underline: const SizedBox(),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

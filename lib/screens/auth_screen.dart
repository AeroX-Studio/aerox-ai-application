/// User authentication and registration screen for AeroX AI.
///
/// Provides credential login, account registration, form validation,
/// "Continue with Google" OAuth authentication, custom backend endpoint configuration,
/// password visibility controls, and ambient glowing micro-interactions.
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/platform_service.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import '../widgets/aerox_button.dart';
import '../widgets/aerox_toast.dart';
import 'dashboard_screen.dart';

/// The authentication screen allowing users to sign in or create accounts.
class AuthScreen extends StatefulWidget {
  /// Creates an [AuthScreen] widget.
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _loginController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _showForgotPasswordDialog() {
    final apiService = ApiService();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AeroXColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AeroXColors.borderPrimary),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Reset Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To reset your password, visit the AeroX AI recovery portal in your browser or contact your organization administrator.',
              style: TextStyle(
                color: AeroXColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AeroXColors.bgInput,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AeroXColors.borderPrimary),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AeroXColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${apiService.effectiveBaseUrl}/forgot-password',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AeroXColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _launchBrowserUrl('${apiService.effectiveBaseUrl}/forgot-password');
            },
            child: const Text('Open Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchBrowserUrl(String url) async {
    try {
      if (kIsWeb) {
        // Handled in web environment
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      } else {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          AeroXToast.show(
            context,
            'Link copied to clipboard. Open in browser to complete authentication.',
            type: AeroXToastType.info,
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        AeroXToast.show(context, 'Link copied to clipboard', type: AeroXToastType.info);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final platform = PlatformService().currentPlatform;
      final deviceId = await PlatformService().getDeviceId();
      final osVersion = PlatformService().currentOsVersion;

      if (_isLogin) {
        await AuthService().login(
          login: _loginController.text.trim(),
          password: _passwordController.text,
          platform: platform,
          deviceId: deviceId,
          osVersion: osVersion,
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception('Passwords do not match');
        }

        await AuthService().register(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          platform: platform,
          deviceId: deviceId,
        );
      }

      await PlatformService().registerDeviceSession(userId: AuthService().currentUser.value?.id);
      await NotificationService().init();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      AeroXToast.show(
        context,
        e.toString().replaceAll('Exception: ', ''),
        type: AeroXToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isLoading) return;

    setState(() => _isGoogleLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user == null) {
        // User cancelled account selection
        return;
      }

      await PlatformService().registerDeviceSession(userId: user.id);
      await NotificationService().init();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = _getFriendlyAuthError(e);
      AeroXToast.show(
        context,
        errorMsg,
        type: AeroXToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  String _getFriendlyAuthError(dynamic e) {
    final raw = e.toString().replaceAll('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('network error') ||
        lower.contains('offline') ||
        lower.contains('cannot resolve host')) {
      return 'Unable to reach AeroX AI servers. Please verify your internet connection.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Connection timed out. Please try again.';
    }
    if (lower.contains('google sign-in configuration error') ||
        lower.contains('12500') ||
        lower.contains('error 10')) {
      return 'Google authentication configuration error. Please verify client setup.';
    }
    if (lower.contains('disabled') || lower.contains('banned') || lower.contains('suspended')) {
      return 'Your account has been deactivated. Please contact support.';
    }
    if (lower.contains('session expired') ||
        lower.contains('session not found') ||
        lower.contains('unauthenticated') ||
        lower.contains('authentication required')) {
      return 'Your session has expired. Please sign in again.';
    }
    return raw.isNotEmpty ? raw : 'Google Sign-In failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 860;
    final isCompact = mediaQuery.size.width < 380;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AeroXColors.bgPrimary,
        body: _buildDesktopSplitLayout(),
      );
    }

    return Scaffold(
      backgroundColor: AeroXColors.bgPrimary,
      body: _buildMobileLayout(isCompact: isCompact),
    );
  }

  /// Responsive desktop split layout matching AeroX AI v2 web architecture.
  Widget _buildDesktopSplitLayout() {
    return Row(
      children: [
        // Left Column: Hero branding section (1.1fr in v2)
        Expanded(
          flex: 11,
          child: Container(
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Brand Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Image.asset(
                          'assets/images/logo_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AeroX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          fontFamily: AeroXTheme.fontDisplay,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Text(
                          'AI',
                          style: AeroXTheme.tech(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Center Hero Headline matching v2 .auth-hero-text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Powerful\nIntelligence.',
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 46,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Experience the next generation of artificial intelligence, designed for deep thought and seamless interaction.',
                      style: GoogleFonts.quicksand(
                        color: AeroXColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                // Bottom Subtitle matching v2 .auth-hero-sub
                Text(
                  'Built by AeroX Studio.',
                  style: GoogleFonts.quicksand(
                    color: AeroXColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Vertical Divider Border
        Container(
          width: 1,
          color: const Color(0xFF1A1A1A),
        ),

        // Right Column: Auth Form Container (1fr in v2)
        Expanded(
          flex: 10,
          child: Container(
            color: AeroXColors.bgPrimary,
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildAuthFormContent(
                    isCompact: false,
                    isSplitLayout: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout with ambient particles and centered card.
  Widget _buildMobileLayout({required bool isCompact}) {
    final cardPadding = isCompact ? 18.0 : 28.0;

    return Stack(
      children: [
        // Ambient floating particles background for subtle depth
        const Positioned.fill(
          child: FloatingParticles(particleCount: 18),
        ),

        // Central radial glow behind the card
        Center(
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.01),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 24,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: AeroXColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AeroXColors.borderPrimary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      offset: const Offset(0, 16),
                      blurRadius: 36,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.03),
                      blurRadius: 40,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: _buildAuthFormContent(
                  isCompact: isCompact,
                  isSplitLayout: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Core authentication form content used across both desktop split and mobile modes.
  Widget _buildAuthFormContent({
    required bool isCompact,
    required bool isSplitLayout,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // On mobile or standalone card, display the top brand mark
          if (!isSplitLayout) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.10),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'AeroX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          fontFamily: AeroXTheme.fontDisplay,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF222222)),
                        ),
                        child: Text(
                          'AI',
                          style: AeroXTheme.tech(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 14),
          ],

          // Title & Subtitle styled after v2 .auth-title.font-body
          Text(
            _isLogin ? 'Welcome back' : 'Create your account',
            textAlign: isSplitLayout ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.quicksand(
              color: Colors.white,
              fontSize: isCompact ? 21 : 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isLogin
                ? 'Sign in to your AeroX AI account'
                : 'Join AeroX AI and start exploring',
            textAlign: isSplitLayout ? TextAlign.start : TextAlign.center,
            style: GoogleFonts.quicksand(
              color: AeroXColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 22),

          // Google Sign-In Button
          _GoogleSignInButton(
            isLoading: _isGoogleLoading,
            onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
          ),
          const SizedBox(height: 18),

          // Divider with elegant hairline
          Row(
            children: [
              const Expanded(child: Divider(color: AeroXColors.borderPrimary, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR CONTINUE WITH',
                  style: GoogleFonts.inter(
                    color: AeroXColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AeroXColors.borderPrimary, height: 1)),
            ],
          ),
          const SizedBox(height: 18),

          // Segmented Tab Switcher (Sign In / Create Account)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF09090D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AeroXColors.borderPrimary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!_isLogin) {
                        setState(() {
                          _isLogin = true;
                          _formKey.currentState?.reset();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _isLogin ? const Color(0xFF1B1B24) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: _isLogin
                            ? Border.all(color: const Color(0xFF2E2E3C), width: 1)
                            : null,
                      ),
                      child: Text(
                        'Sign In',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isLogin ? Colors.white : AeroXColors.textSecondary,
                          fontWeight: _isLogin ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_isLogin) {
                        setState(() {
                          _isLogin = false;
                          _formKey.currentState?.reset();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: !_isLogin ? const Color(0xFF1B1B24) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: !_isLogin
                            ? Border.all(color: const Color(0xFF2E2E3C), width: 1)
                            : null,
                      ),
                      child: Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isLogin ? Colors.white : AeroXColors.textSecondary,
                          fontWeight: !_isLogin ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Form Fields
          if (_isLogin) ...[
            TextFormField(
              controller: _loginController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Email or Username',
                hintText: 'name@example.com or username',
                prefixIcon: Icon(
                  Icons.alternate_email_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your login' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AeroXColors.textSecondary,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AeroXColors.textSecondary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AeroXColors.textTertiary,
                  ),
                ),
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'you@domain.com',
                prefixIcon: Icon(
                  Icons.mail_outline_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) return 'Valid email required';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username (min 3 chars)',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username is required';
                if (v.trim().length < 3) return 'Username must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Minimum 8 characters',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: AeroXColors.textSecondary,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(
                  Icons.lock_reset_rounded,
                  size: 18,
                  color: AeroXColors.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: AeroXColors.textSecondary,
                  ),
                  tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],

          const SizedBox(height: 22),

          // Main Submit Button
          AeroXButton(
            text: _isLogin ? 'Sign In' : 'Create Account',
            isLoading: _isLoading,
            isFullWidth: true,
            size: AeroXButtonSize.lg,
            onPressed: _submit,
          ),

          const SizedBox(height: 18),

          // Toggle Tab footer prompt
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _formKey.currentState?.reset();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.quicksand(
                      color: AeroXColors.textSecondary,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: _isLogin ? "Don't have an account? " : 'Already have an account? ',
                      ),
                      TextSpan(
                        text: _isLogin ? 'Create one' : 'Sign in',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Terms & Privacy disclaimer
          const Text(
            'By continuing, you agree to AeroX AI’s Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AeroXColors.textTertiary,
              fontSize: 11,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),

          // Production Environment Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF121218),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E1E28)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AeroXColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AeroX AI • Cloud Production',
                      style: TextStyle(
                        color: AeroXColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Official "Continue with Google" interactive button.
///
/// Features sharp vector Google G branding, hover glow, and press micro-animations.
class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _GoogleSignInButton({
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) {
          if (isEnabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTapCancel: () {
          if (isEnabled) setState(() => _isPressed = false);
        },
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 48,
            decoration: BoxDecoration(
              color: isEnabled
                  ? (_isHovered ? const Color(0xFFF2F2F4) : Colors.white)
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? const Color(0xFFE2E2E8) : Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.16),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _GoogleIcon(size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Color(0xFF0A0A0A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
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

/// Official Google 'G' icon rendered with sharp vector Canvas path math.
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
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Blue right arm & arc (#4285F4)
    final pathBlue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
      ..lineTo(15.71, 20.34)
      ..lineTo(19.28, 20.34)
      ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(
      pathBlue,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Green bottom arc (#34A853)
    final pathGreen = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.34)
      ..lineTo(15.71, 17.57)
      ..cubicTo(14.73, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(
      pathGreen,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Yellow left arc (#FBBC05)
    final pathYellow = Path()
      ..moveTo(5.84, 14.1)
      ..cubicTo(5.62, 13.44, 5.49, 12.74, 5.49, 12.0)
      ..cubicTo(5.49, 11.26, 5.62, 10.56, 5.84, 9.9)
      ..lineTo(5.84, 7.07)
      ..lineTo(2.18, 7.07)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.93)
      ..lineTo(5.03, 14.71)
      ..close();
    canvas.drawPath(
      pathYellow,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // Red top arc (#EA4335)
    final pathRed = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.07)
      ..lineTo(5.84, 9.91)
      ..cubicTo(6.71, 7.31, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(
      pathRed,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

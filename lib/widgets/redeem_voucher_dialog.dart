/// Animated voucher redemption dialog for AeroX AI.
///
/// Features animated modal entrance, ticket glowing emblem, uppercase code formatting,
/// instant backend validation, and credit replenishment feedback.
library;

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/aerox_animations.dart';
import '../theme/aerox_colors.dart';
import '../theme/aerox_theme.dart';
import 'aerox_toast.dart';

/// Modal dialog for redeeming gift cards, promo codes, and credit vouchers.
class RedeemVoucherDialog extends StatefulWidget {
  /// Optional callback invoked after successful redemption.
  final VoidCallback? onSuccess;

  const RedeemVoucherDialog({super.key, this.onSuccess});

  /// Displays the animated dialog over the given [context].
  static Future<bool?> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: AeroXAnimations.normal,
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: AeroXAnimations.easeSpring);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, _, _) => RedeemVoucherDialog(onSuccess: onSuccess),
    );
  }

  @override
  State<RedeemVoucherDialog> createState() => _RedeemVoucherDialogState();
}

class _RedeemVoucherDialogState extends State<RedeemVoucherDialog> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _redeemResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitRedeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a voucher code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final res = await _authService.redeemVoucher(code);
      final msg = res['message']?.toString() ?? 'Voucher redeemed successfully!';

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = msg;
          _redeemResult = res;
        });

        widget.onSuccess?.call();
        AeroXToast.show(context, msg, type: AeroXToastType.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AeroXColors.bgElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AeroXColors.borderPrimary, width: 1.2),
            boxShadow: const [
              AeroXColors.shadowLg,
              BoxShadow(
                color: Color(0x18FFFFFF),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Glowing Ticket Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AeroXColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AeroXColors.borderFocus),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15FFFFFF),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AeroXColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title and Subtitle
              Text(
                'Redeem Voucher',
                style: AeroXTheme.heading(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your voucher or promo code to immediately add credits or activate your package tier.',
                style: AeroXTheme.body(
                  fontSize: 13,
                  color: AeroXColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Error banner if any
              if (_errorMessage != null) ...[
                AnimatedContainer(
                  duration: AeroXAnimations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AeroXColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AeroXColors.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AeroXColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AeroXColors.error, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Success banner if any
              if (_successMessage != null) ...[
                AnimatedContainer(
                  duration: AeroXAnimations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AeroXColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AeroXColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AeroXColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: AeroXColors.success, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (_redeemResult != null)
                _buildRedeemResult()
              else ...[
                // Input field
                Container(
                  decoration: BoxDecoration(
                    color: AeroXColors.bgInput,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AeroXColors.borderPrimary),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, color: AeroXColors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          focusNode: _focusNode,
                          style: AeroXTheme.mono(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'e.g. AEROX-PRO-2025',
                            hintStyle: TextStyle(
                              color: AeroXColors.textMuted,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _submitRedeem(),
                        ),
                      ),
                      if (_codeController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: AeroXColors.textTertiary, size: 16),
                          onPressed: () {
                            _codeController.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AeroXColors.textSecondary,
                          side: const BorderSide(color: AeroXColors.borderPrimary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel', style: AeroXTheme.body(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _submitRedeem,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('✦', style: TextStyle(color: Colors.black, fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Redeem Voucher',
                                    style: AeroXTheme.body(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemResult() {
    final plan = _redeemResult!['planReceived']?.toString();
    final duration = _redeemResult!['duration']?.toString();
    final start = _redeemResult!['startDateFormatted']?.toString();
    final expires = _redeemResult!['expiresDateFormatted']?.toString();
    final remaining = _redeemResult!['remainingTime']?.toString();
    final credits = _redeemResult!['creditsAdded'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AeroXColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AeroXColors.borderFocus),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan != null) ...[
                _buildResultRow('Plan received:', plan, isHighlight: true),
                const SizedBox(height: 10),
                if (duration != null) _buildResultRow('Duration:', duration),
                const SizedBox(height: 10),
                if (start != null) _buildResultRow('Start:', start),
                const SizedBox(height: 10),
                if (expires != null) _buildResultRow('Expires:', expires),
                const SizedBox(height: 10),
                if (remaining != null) _buildResultRow('Remaining:', remaining),
              ] else if (credits != null) ...[
                _buildResultRow('Credits added:', '+$credits credits', isHighlight: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Done',
            style: AeroXTheme.body(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AeroXTheme.body(fontSize: 12.5, color: AeroXColors.textSecondary)),
        Text(
          value,
          style: isHighlight
              ? AeroXTheme.heading(fontSize: 14, fontWeight: FontWeight.w700, color: AeroXColors.accent)
              : AeroXTheme.mono(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ],
    );
  }
}

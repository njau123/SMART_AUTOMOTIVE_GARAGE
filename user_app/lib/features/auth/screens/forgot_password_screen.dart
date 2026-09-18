import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;

  // Countdown
  Timer? _timer;
  int _secondsLeft = 0;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  void _startCountdown({int seconds = 600}) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _countdownText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _requestCode({bool resend = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await AuthAPI.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _step = 1);
      _startCountdown();
      _snack(
        resend
            ? 'New code sent to ${_email.text.trim()}'
            : 'Code sent to ${_email.text.trim()}',
      );
      if (data['email_sent'] != true) {
        _snack(
          'Note: Email server offline. Code: ${data['debug_code'] ?? 'N/A'}',
          error: true,
        );
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().isEmpty) {
      _snack('Enter the code', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthAPI.verifyResetCode(_email.text.trim(), _code.text.trim());
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _step = 2);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPass.text.length < 6) {
      _snack('Password must be at least 6 characters', error: true);
      return;
    }
    if (_newPass.text != _confirmPass.text) {
      _snack("Passwords don't match", error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthAPI.confirmPasswordReset(
        email: _email.text.trim(),
        code: _code.text.trim(),
        newPassword: _newPass.text,
      );
      if (!mounted) return;
      setState(() => _step = 3);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(key: _formKey, child: _buildStep()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 3) return _buildSuccess();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _step == 0
                  ? Icons.lock_reset
                  : _step == 1
                      ? Icons.verified_outlined
                      : Icons.password,
              color: AppColors.primary,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _step == 0
              ? 'Forgot password?'
              : _step == 1
                  ? 'Enter verification code'
                  : 'Set new password',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _step == 0
              ? 'Enter your email to receive a reset code.'
              : _step == 1
                  ? 'We sent a 6-digit code to ${_email.text.trim()}'
                  : 'Choose a strong new password.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        if (_step == 0) ..._emailStep(),
        if (_step == 1) ..._codeStep(),
        if (_step == 2) ..._passwordStep(),
      ],
    );
  }

  List<Widget> _emailStep() => [
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'you@example.com',
            prefixIcon: Icon(Icons.mail_outline, size: 20),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 20),
        _primaryBtn('Send reset code', _loading ? null : () => _requestCode()),
      ];

  List<Widget> _codeStep() => [
        TextFormField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
            prefixIcon: Icon(Icons.numbers, size: 20),
          ),
        ),
        const SizedBox(height: 12),
        // Countdown timer
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _canResend
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _canResend ? Icons.timer_off : Icons.timer_outlined,
                  size: 18,
                  color: _canResend ? AppColors.danger : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _canResend ? 'Code expired' : 'Expires in $_countdownText',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _canResend ? AppColors.danger : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _primaryBtn(
          'Verify code',
          _loading || _canResend ? null : _verifyCode,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _loading || !_canResend
              ? null
              : () => _requestCode(resend: true),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            'Resend code',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: _canResend ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ),
      ];

  List<Widget> _passwordStep() => [
        TextFormField(
          controller: _newPass,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.length < 6) return 'At least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPass,
          obscureText: _obscure,
          decoration: const InputDecoration(
            hintText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_outline, size: 20),
          ),
        ),
        const SizedBox(height: 20),
        _primaryBtn('Reset password', _loading ? null : _resetPassword),
      ];

  Widget _buildSuccess() => Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: 20),
          Text('Password reset!',
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Your password has been changed. You can now sign in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          _primaryBtn('Back to sign in', () => Navigator.pop(context)),
        ],
      );

  Widget _primaryBtn(String text, VoidCallback? onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: _loading && onPressed != null
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(text),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';

/// Inasimamia session timeout (dakika 10).
class SessionGuard {
  SessionGuard._();
  static final SessionGuard instance = SessionGuard._();

  Timer? _timer;
  BuildContext? _context;
  static const Duration _sessionDuration = Duration(minutes: 10);

  /// Anza timer baada ya login.
  void start(BuildContext context) {
    _context = context;
    _timer?.cancel();
    _timer = Timer(_sessionDuration, () {
      _autoLogout();
    });
  }

  /// Reset timer kila user anapofanya kitu.
  void touch() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = Timer(_sessionDuration, () {
        _autoLogout();
      });
    }
  }

  /// Simamisha timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _autoLogout() async {
    await AuthState.instance.logout();
    final ctx = _context;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text(
            'Session imeisha kwa usalama. Tafadhali ingia tena.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

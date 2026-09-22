import 'dart:async';
import 'package:flutter/material.dart';
import '../state/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';

/// Inasimamia session timeout (dakika 30).
/// Inaheshimu tab visibility — ukirudi kwenye tab, session inaendelea.
class SessionGuard with WidgetsBindingObserver {
  SessionGuard._();
  static final SessionGuard instance = SessionGuard._();

  Timer? _timer;
  BuildContext? _context;
  DateTime? _lastActivity;
  bool _initialized = false;
  static const Duration _sessionDuration = Duration(minutes: 30);

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App imerudi — angalia kama session imeisha
      _checkExpiry();
    }
  }

  void _checkExpiry() {
    if (_lastActivity == null) return;
    final elapsed = DateTime.now().difference(_lastActivity!);
    if (elapsed >= _sessionDuration) {
      _autoLogout();
    } else {
      // Restart timer na muda uliobaki
      final remaining = _sessionDuration - elapsed;
      _timer?.cancel();
      _timer = Timer(remaining, _autoLogout);
    }
  }

  /// Anza timer baada ya login.
  void start(BuildContext context) {
    init();
    _context = context;
    _lastActivity = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_sessionDuration, _autoLogout);
  }

  /// Reset timer kila user anapofanya kitu.
  void touch() {
    _lastActivity = DateTime.now();
    if (_timer != null) {
      _timer?.cancel();
      _timer = Timer(_sessionDuration, _autoLogout);
    }
  }

  /// Simamisha timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastActivity = null;
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

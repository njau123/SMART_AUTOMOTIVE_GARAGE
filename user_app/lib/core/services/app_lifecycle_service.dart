import 'package:flutter/material.dart';
import 'api_service.dart';
import '../state/auth_state.dart';

/// Inasikiliza lifecycle ya app ili kufuta session
/// wakati user anatoka kabisa kwenye mfumo.
class AppLifecycleService extends WidgetsBindingObserver {
  static final AppLifecycleService _instance =
      AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  bool _initialized = false;
  DateTime? _lastPausedAt;

  void initialize() {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _lastPausedAt = DateTime.now();
        break;

      case AppLifecycleState.detached:
        // App inafungwa kabisa — futa session
        try {
          await TokenStorage.clear();
          await AuthState.instance.logout(showMessage: false);
        } catch (e) {
          debugPrint('[Lifecycle] Logout error: $e');
        }
        break;

      case AppLifecycleState.resumed:
        // Kama alikaa mbali > 30 min, futa session pia
        if (_lastPausedAt != null) {
          final away = DateTime.now().difference(_lastPausedAt!);
          if (away.inMinutes >= 30) {
            try {
              await TokenStorage.clear();
              await AuthState.instance.logout(showMessage: false);
            } catch (e) {
              debugPrint('[Lifecycle] Timeout logout: $e');
            }
          }
        }
        _lastPausedAt = null;
        break;
      default:
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }
}

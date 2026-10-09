import 'package:flutter/material.dart';

/// SessionGuard — NO-OP version.
/// User anaendelea kuingia mpaka afanye logout mwenyewe.
/// Hatu-logout automatically.
class SessionGuard with WidgetsBindingObserver {
  SessionGuard._();
  static final SessionGuard instance = SessionGuard._();

  void init() {
    // No-op — hatufanyi chochote
  }

  /// Anza "session" — kwa sasa ni no-op.
  void start(BuildContext context) {
    // No-op — session haitaisha
  }

  /// Reset "timer" — no-op.
  void touch() {
    // No-op
  }

  /// Simamisha — no-op.
  void stop() {
    // No-op
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op — hatucheki expiry
  }
}

import '../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Global auth state - inasikilizwa na widgets zote.
class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._();
  AuthState._();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  bool _showLogoutMessage = false;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  bool get showLogoutMessage => _showLogoutMessage;

  Future<void> init() async {
    _isLoggedIn = await TokenStorage.isLoggedIn();
    _user = await TokenStorage.getUser();
    notifyListeners();

    // Background refresh — sio kuzuia startup
    if (_isLoggedIn) {
      _refreshInBackground();
    }
  }

  /// Refresh profile kutoka backend bila kuzuia app.
  /// Inasahihisha: profile_image, region, jina, n.k.
  Future<void> _refreshInBackground() async {
    try {
      final fresh = await AuthAPI.getProfile();
      if (fresh.isNotEmpty) {
        _user = {...?_user, ...fresh};
        await TokenStorage.saveUser(_user!);
        notifyListeners();
        debugPrint('[Auth] Profile refreshed');
      }
    } catch (e) {
      debugPrint('[Auth] Refresh failed: $e');
    }
  }

  /// Force refresh (public).
  Future<void> refreshProfile() async {
    await _refreshInBackground();
  }

  Future<void> login(Map<String, dynamic> user) async {
    _isLoggedIn = true;
    _user = user;
    _showLogoutMessage = false;
    notifyListeners();
  }

  Future<void> logout({bool showMessage = true}) async {
    // 1. Futa FCM token + ALL devices za user (safety cleanup)
    try {
      await NotificationService.instance.clearAllDevices();
    } catch (_) {}

    // 2. Futa FCM token kwenye device yenyewe
    try {
      final fcm = FirebaseMessaging.instance;
      await fcm.deleteToken();
    } catch (_) {}

    // 3. Futa tokens + cached user
    await TokenStorage.clear();

    // 4. Futa state
    _isLoggedIn = false;
    _user = null;
    _showLogoutMessage = showMessage;
    notifyListeners();
  }

  void clearLogoutMessage() {
    _showLogoutMessage = false;
    notifyListeners();
  }

  /// Update user data (mfano baada ya profile refresh).
  Future<void> updateUser(Map<String, dynamic> newData) async {
    _user = {...?_user, ...newData};
    await TokenStorage.saveUser(_user!);
    notifyListeners();
  }

}

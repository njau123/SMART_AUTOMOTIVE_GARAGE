import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AdminAuthState extends ChangeNotifier {
  static final AdminAuthState instance = AdminAuthState._();
  AdminAuthState._();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    _isLoggedIn = await AdminTokenStorage.isLoggedIn();
    _user = await AdminTokenStorage.getUser();
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> user) async {
    _isLoggedIn = true;
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await AdminTokenStorage.clear();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    return await AdminTokenStorage.getUser();
  }
}

// Alias ili kifurushi kitumike kwa admin_login
class AdminAuthStorage {
  static Future<Map<String, dynamic>?> getUser() =>
      AdminTokenStorage.getUser();
}

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
  }

  Future<void> login(Map<String, dynamic> user) async {
    _isLoggedIn = true;
    _user = user;
    _showLogoutMessage = false;
    notifyListeners();
  }

  Future<void> logout({bool showMessage = true}) async {
    await TokenStorage.clear();
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

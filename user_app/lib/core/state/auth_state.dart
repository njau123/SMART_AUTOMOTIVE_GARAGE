import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Global auth state - inasikilizwa na widgets zote.
class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._();
  AuthState._();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;

  Future<void> init() async {
    _isLoggedIn = await TokenStorage.isLoggedIn();
    _user = await TokenStorage.getUser();
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> user) async {
    _isLoggedIn = true;
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}

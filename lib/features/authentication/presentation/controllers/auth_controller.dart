import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_api_datasource.dart';
class AuthController extends ChangeNotifier {
  final AuthApiDataSource _api = AuthApiDataSource();
  String? _accessToken; String? _refreshToken; bool _isLoading = false; String? _error;
  String? get accessToken => _accessToken; bool get isLoading => _isLoading; String? get error => _error; bool get isLoggedIn => _accessToken != null;
  Future<void> loadTokens() async { final prefs = await SharedPreferences.getInstance(); _accessToken = prefs.getString('access_token'); _refreshToken = prefs.getString('refresh_token'); notifyListeners(); }
  Future<bool> login(String email, String password) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final data = await _api.login(email, password);
      if (data != null && data['access'] != null) {
        _accessToken = data['access']; _refreshToken = data['refresh'];
        final prefs = await SharedPreferences.getInstance(); await prefs.setString('access_token', _accessToken!); await prefs.setString('refresh_token', _refreshToken!);
        _isLoading = false; notifyListeners(); return true;
      }
      _isLoading = false; notifyListeners(); return false;
    } catch (e) { _error = e.toString(); _isLoading = false; notifyListeners(); return false; }
  }
  Future<bool> register({required String email, required String password, required String firstName, required String lastName, required String phone}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final data = await _api.register(email: email, password: password, firstName: firstName, lastName: lastName, phone: phone);
      if (data != null && data['access'] != null) {
        _accessToken = data['access']; _refreshToken = data['refresh'];
        final prefs = await SharedPreferences.getInstance(); await prefs.setString('access_token', _accessToken!); await prefs.setString('refresh_token', _refreshToken!);
        _isLoading = false; notifyListeners(); return true;
      }
      _isLoading = false; notifyListeners(); return false;
    } catch (e) { _error = e.toString(); _isLoading = false; notifyListeners(); return false; }
  }
  Future<void> logout() async { _accessToken = null; _refreshToken = null; final prefs = await SharedPreferences.getInstance(); await prefs.remove('access_token'); await prefs.remove('refresh_token'); notifyListeners(); }
}

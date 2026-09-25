import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider ya lugha — inahifadhi chaguo la user.
class LanguageProvider extends ChangeNotifier {
  static const _key = 'app_language';
  static const _defaultLang = 'sw';

  Locale _locale = const Locale(_defaultLang);
  bool _loaded = false;

  Locale get locale => _locale;
  bool get loaded => _loaded;
  bool get isSwahili => _locale.languageCode == 'sw';
  bool get isEnglish => _locale.languageCode == 'en';

  LanguageProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key) ?? _defaultLang;
      if (['sw', 'en'].contains(code)) {
        _locale = Locale(code);
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> changeLanguage(String code) async {
    if (!['sw', 'en'].contains(code)) return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
  }

  Future<void> setSwahili() => changeLanguage('sw');
  Future<void> setEnglish() => changeLanguage('en');
}

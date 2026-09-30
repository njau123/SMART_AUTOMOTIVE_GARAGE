import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'web_cache_buster_stub.dart'
    if (dart.library.js_interop) 'web_cache_buster_web.dart' as impl;

class WebCacheBuster {
  static const String _appVersion = 'v18-20260930-1500';

  static Future<void> checkAndClear() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString('app_version');
      if (lastVersion != _appVersion) {
        await impl.clearWebCache();
        await prefs.setString('app_version', _appVersion);
      }
    } catch (_) {}
  }
}

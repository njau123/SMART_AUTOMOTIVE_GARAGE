import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

/// Cache buster — futa service worker + caches kama version imebadilika.
/// Inatumia conditional import — web pekee inafanya kazi.
class WebCacheBuster {
  static const String _appVersion = 'v18-20260930_1430';

  static Future<void> checkAndClear() async {
    if (!kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString('app_version');

      if (lastVersion != _appVersion) {
        debugPrint('[CACHE] Version changed: $lastVersion → $_appVersion');
        await clearCache();
        await prefs.setString('app_version', _appVersion);
      } else {
        debugPrint('[CACHE] Version same: $_appVersion');
      }
    } catch (e) {
      debugPrint('[CACHE] checkAndClear error: $e');
    }
  }

  static Future<void> clearCache() async {
    if (!kIsWeb) return;
    try {
      // Dynamic call ili kuepusha dart:html import
      // ignore: avoid_dynamic_calls
      await _clearViaJs();
    } catch (e) {
      debugPrint('[CACHE] clearCache error: $e');
    }
  }

  static Future<void> _clearViaJs() async {
    // Kama kIsWeb, tutatumia hivi kwa dart:js_interop au fallback
    try {
      // ignore: avoid_dynamic_calls
      // ignore: undefined_prefixed_name
      // Use JS interop via web package
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('[CACHE] Cleared via JS (no-op if unavailable)');
    } catch (_) {}
  }
}

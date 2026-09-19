/// Auto-Update Service kwa Flutter Web.
///
/// Inafanya kazi hivi:
///   1. Inasoma /version.json (Flutter inaitengeneza automatically)
///   2. Kila dakika 3, ina-check kama version imebadilika
///   3. Kama imebadilika:
///      - Unregister service workers
///      - Clear caches
///      - Reload app
///
/// Hii inasuluhisha tatizo la "cache" — user hahitaji ku-clear cache manually.
library;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  static const Duration _checkInterval = Duration(minutes: 3);
  static String? _currentBuild;
  static Timer? _timer;
  static bool _updating = false;

  /// Anza update service. Itafanya kazi automatically.
  static Future<void> init() async {
    await _loadCurrentVersion();

    // Check kila dakika 3
    _timer?.cancel();
    _timer = Timer.periodic(_checkInterval, (_) => _checkForUpdate());

    // Check pia user anaporudi kwenye tab
    try {
      html.document.onVisibilityChange.listen((_) {
        if (html.document.visibilityState == 'visible') {
          _checkForUpdate();
        }
      });
    } catch (e) {
      debugPrint('[UpdateService] Visibility listener failed: $e');
    }

    debugPrint('[UpdateService] Started. Current: $_currentBuild');
  }

  static Future<void> _loadCurrentVersion() async {
    try {
      final url = '/version.json?t=${DateTime.now().millisecondsSinceEpoch}';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _currentBuild = data['build_number']?.toString() ??
            data['version']?.toString();
        debugPrint('[UpdateService] Loaded version: $_currentBuild');
      }
    } catch (e) {
      debugPrint('[UpdateService] Load version error: $e');
    }
  }

  static Future<void> _checkForUpdate() async {
    if (_updating) return;

    try {
      final url = '/version.json?t=${DateTime.now().millisecondsSinceEpoch}';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body);
      final newBuild = data['build_number']?.toString() ??
          data['version']?.toString();

      if (_currentBuild != null &&
          newBuild != null &&
          newBuild != _currentBuild) {
        debugPrint(
            '[UpdateService] 🆕 New version: $newBuild (was $_currentBuild)');
        _updating = true;
        await _applyUpdate();
      }
    } catch (e) {
      debugPrint('[UpdateService] Check error: $e');
    }
  }

  static Future<void> _applyUpdate() async {
    debugPrint('[UpdateService] Applying update...');

    // 1. Unregister service workers
    try {
      final sw = html.window.navigator.serviceWorker;
      if (sw != null) {
        final regs = await sw.getRegistrations();
        for (final reg in regs) {
          await reg.unregister();
        }
        debugPrint('[UpdateService] SW unregistered: ${regs.length}');
      }
    } catch (e) {
      debugPrint('[UpdateService] SW unregister error: $e');
    }

    // 2. Clear caches
    try {
      final caches = html.window.caches;
      if (caches != null) {
        final keys = await caches.keys();
        for (final key in keys) {
          await caches.delete(key);
        }
        debugPrint('[UpdateService] Caches cleared: ${keys.length}');
      }
    } catch (e) {
      debugPrint('[UpdateService] Cache clear error: $e');
    }

    // 3. Reload
    debugPrint('[UpdateService] Reloading...');
    await Future.delayed(const Duration(milliseconds: 300));
    html.window.location.reload();
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'Smart Garage Mechanic';
  static const String appVersion = '1.0.0';

  /// Base URL ya backend.
  ///
  /// - Web: http://localhost:8000/api/v1/
  /// - Android emulator: http://10.0.2.2:8000/api/v1/
  /// - iOS simulator: http://localhost:8000/api/v1/
  /// - Kifaa halisi: badilisha na IP ya kompyuta yako
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1/';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 = kompyuta yako kutoka ndani ya emulator
      return 'http://10.0.2.2:8000/api/v1/';
    }
    // iOS, macOS, Windows, Linux
    return 'http://localhost:8000/api/v1/';
  }
}

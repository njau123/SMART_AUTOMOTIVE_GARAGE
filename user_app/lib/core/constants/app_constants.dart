import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Automotive Garage';
  static const String appTagline = 'Your car, our priority';
  static const String appVersion = '1.0.0';

  /// ============================================
  /// BACKEND URL — inategemea environment
  /// ============================================
  /// - Web (Chrome): localhost
  /// - Android Emulator: 10.0.2.2
  /// - Simu Halisi (WiFi moja): IP ya PC
  /// ============================================
  static const String _pcIp = '192.168.1.174';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1/';
    if (Platform.isAndroid) {
      // Simu halisi inatumia IP ya PC
      return 'http://$_pcIp:8000/api/v1/';
    }
    return 'http://localhost:8000/api/v1/';
  }

  /// Session timeouts
  static const int userSessionMinutes = 10;
  static const int adminSessionHours = 3;

  /// Payment info (imefichwa kwa UI)
  static const String companyName = 'Automotive Smart Garage';
  static const String companyPhone = 'Automotive Smart Garage Account';
}

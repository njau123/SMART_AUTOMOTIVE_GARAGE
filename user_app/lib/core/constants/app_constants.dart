import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Automotive Garage';
  static const String appTagline = 'Your car, our priority';
  static const String appVersion = '1.0.0';

  /// ============================================
  /// BACKEND URL — environment-based
  /// ============================================
  /// - Web (Vercel/Chrome): Render production
  /// - Android (dev): PC IP (badilisha kama inahitajika)
  /// - iOS/macOS/Linux (dev): localhost
  /// ============================================
  static const String productionUrl = 'https://smart-garage-backend.onrender.com/api/v1/';
  static const String _pcIp = '192.168.1.174';

  static String get baseUrl {
    // WEB = production (Vercel)
    if (kIsWeb) return productionUrl;

    // Mobile/Desktop = dev (local backend)
    if (Platform.isAndroid) {
      return 'http://$_pcIp:8000/api/v1/';
    }
    return 'http://localhost:8000/api/v1/';
  }

  /// Session timeouts
  static const int userSessionMinutes = 10;
  static const int adminSessionHours = 3;

  /// Payment info
  static const String companyName = 'Automotive Smart Garage';
  static const String companyPhone = 'Automotive Smart Garage Account';
}

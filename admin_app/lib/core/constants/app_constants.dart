import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  static const String appName = 'Smart Garage Admin';
  static const String appTagline = 'Manage your garage';
  static const String appVersion = '1.0.0';

  static const int adminSessionHours = 3;
  static const String companyName = 'Automotive Smart Garage';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1/';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1/';
    return 'http://localhost:8000/api/v1/';
  }
}

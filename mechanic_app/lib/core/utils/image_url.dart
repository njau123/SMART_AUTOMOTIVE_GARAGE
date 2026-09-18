import '../constants/app_constants.dart';

/// Helper ya kujenga URL kamili ya picha kutoka backend.
class ImageUrl {
  static String from(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    // baseUrl = 'http://10.0.2.2:8000/api/v1/'
    // Tunahitaji host pekee: 'http://10.0.2.2:8000'
    final base = AppConstants.baseUrl;
    final host = base.replaceAll(RegExp(r'/api/v1/?$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$host$cleanPath';
  }
}

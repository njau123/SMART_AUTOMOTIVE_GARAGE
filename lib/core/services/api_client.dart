import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiClient {
  static Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: {'Content-Type': 'application/json', ...?headers}, body: jsonEncode(body ?? {}));
    return _handleResponse(response);
  }
  static Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: headers);
    return _handleResponse(response);
  }
  static Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final response = await http.put(Uri.parse('${ApiConfig.baseUrl}$endpoint'), headers: {'Content-Type': 'application/json', ...?headers}, body: jsonEncode(body ?? {}));
    return _handleResponse(response);
  }
  static dynamic _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['detail'] ?? data.toString());
  }
}

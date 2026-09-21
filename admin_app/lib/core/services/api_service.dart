import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AdminTokenStorage {
  static const _accessKey = 'admin_access_token';
  static const _refreshKey = 'admin_refresh_token';
  static const _loginTimeKey = 'admin_login_time';
  static const _userKey = 'admin_user_data';

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    await prefs.setInt(_loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<bool> isLoggedIn() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_loginTimeKey);
    if (loginTime == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - loginTime;
    return (elapsed / 3600000) > AppConstants.adminSessionHours;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_userKey);
  }
}

class ApiService {
  static Future<dynamic> get(String endpoint, {String? token}) async {
    final r = await http.get(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handle(r);
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final r = await http.post(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handle(r);
  }

  /// POST multipart - inafanya kazi Web + Mobile (bytes, si File).
  /// TUMA: fileBytes = {'main_image': bytesList}, fileNames = {'main_image': 'x.jpg'}
  static Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, List<int>>? fileBytes,
    Map<String, String>? fileNames,
    String? token,
    String method = 'POST',
  }) async {
    final uri = Uri.parse(AppConstants.baseUrl + endpoint);
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);
    if (fileBytes != null) {
      for (final entry in fileBytes.entries) {
        final filename = fileNames?[entry.key] ?? 'upload.jpg';
        request.files.add(
          http.MultipartFile.fromBytes(
            entry.key,
            entry.value,
            filename: filename,
          ),
        );
      }
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handle(response);
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final r = await http.patch(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handle(r);
  }

  static Future<dynamic> delete(
    String endpoint, {
    String? token,
  }) async {
    final r = await http.delete(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handle(r);
  }

  static dynamic _handle(http.Response response) {
    final raw = response.body;
    dynamic data;
    try {
      data = raw.isEmpty ? {} : jsonDecode(raw);
    } catch (_) {
      data = {'detail': raw};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    String message;
    if (data is Map) {
      if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      } else {
        final first = data.values.firstWhere(
          (v) => v != null && (v is! List || v.isNotEmpty),
          orElse: () => null,
        );
        if (first is List && first.isNotEmpty) {
          message = first.first.toString();
        } else {
          message = first?.toString() ?? 'Request failed';
        }
      }
    } else {
      message = data.toString();
    }
    throw Exception(message);
  }

  static List<dynamic> asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'];
    if (data is Map && data['data'] is List) return data['data'];
    return [];
  }
}

class AdminAuthAPI {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiService.post('auth/login/', {
      'email': email,
      'password': password,
    });
    if (data is Map && data['access'] != null) {
      await AdminTokenStorage.saveTokens(
        data['access'].toString(),
        data['refresh']?.toString() ?? '',
      );
      final profile = await getProfile();
      await AdminTokenStorage.saveUser(profile);
    }
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AdminTokenStorage.getAccessToken();
    final raw = await ApiService.get('users/profile/', token: token);
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<Map<String, dynamic>> checkAdmin() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/check/', token: token);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final data = await ApiService.post(
      'auth/password-reset/request/',
      {'email': email},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    final data = await ApiService.post(
      'auth/password-reset/verify/',
      {'email': email, 'code': code},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final data = await ApiService.post(
      'auth/password-reset/confirm/',
      {'email': email, 'code': code, 'new_password': newPassword},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> logout() async {
    await AdminTokenStorage.clear();
  }
}

class AdminAPI {
  static Future<Map<String, dynamic>> getStats() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/stats/', token: token);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getUsers() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/users/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> blockUser(int id, {bool unblock = false}) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'admin/users/$id/block/',
      {'action': unblock ? 'unblock' : 'block'},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> deleteUser(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.delete(
      'admin/users/$id/delete/',
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getMechanics() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/mechanics/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> toggleMechanic(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'admin/mechanics/$id/toggle/',
      {},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getPayments() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/payments/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> verifyPayment(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'admin/payments/$id/verify/',
      {},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getBookings() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/bookings/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> createAdvertisement({
    required String title,
    required String description,
    Uint8List? imageBytes,
    Uint8List? videoBytes,
    String? imageName,
    String? videoName,
    String adType = 'BANNER',
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final Map<String, List<int>> fileBytes = {};
    final Map<String, String> fileNames = {};
    if (imageBytes != null && imageBytes.isNotEmpty) {
      fileBytes['image'] = imageBytes;
      fileNames['image'] = imageName ?? 'ad.jpg';
    }
    if (videoBytes != null && videoBytes.isNotEmpty) {
      fileBytes['video'] = videoBytes;
      fileNames['video'] = videoName ?? 'ad.mp4';
    }
    return await ApiService.postMultipart(
      'admin/advertisements/create/',
      fields: {
        'title': title,
        'description': description,
        'advertisement_type': adType,
      },
      fileBytes: fileBytes.isEmpty ? null : fileBytes,
      fileNames: fileNames.isEmpty ? null : fileNames,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> createNews({
    required String title,
    required String content,
    Uint8List? featuredImageBytes,
    Uint8List? videoFileBytes,
    String? featuredImageName,
    String? videoFileName,
    String? videoUrl,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final Map<String, List<int>> fileBytes = {};
    final Map<String, String> fileNames = {};
    if (featuredImageBytes != null && featuredImageBytes.isNotEmpty) {
      fileBytes['featured_image'] = featuredImageBytes;
      fileNames['featured_image'] = featuredImageName ?? 'news.jpg';
    }
    if (videoFileBytes != null && videoFileBytes.isNotEmpty) {
      fileBytes['video_file'] = videoFileBytes;
      fileNames['video_file'] = videoFileName ?? 'news.mp4';
    }
    return await ApiService.postMultipart(
      'admin/news/create/',
      fields: {
        'title': title,
        'content': content,
        if (videoUrl != null) 'video_url': videoUrl,
      },
      fileBytes: fileBytes.isEmpty ? null : fileBytes,
      fileNames: fileNames.isEmpty ? null : fileNames,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> sendNotification({
    required String title,
    required String message,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'admin/notifications/send/',
      {'title': title, 'message': message},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  // ============ SPARE PARTS CRUD ============
  static Future<List<dynamic>> getSpareParts() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/spare-parts/all/', token: token);
    // Response: {success, count, data: [...]}
    if (data is Map && data['data'] is List) {
      return data['data'] as List;
    }
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> createSparePart({
    required String name,
    required String description,
    required double price,
    String brand = "",
    String partNumber = "",
    int stock = 0,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    return await ApiService.postMultipart(
      'admin/spare-parts/create/',
      fields: {
        'name': name,
        'description': description,
        'price': price.toStringAsFixed(2),
        if (brand.isNotEmpty) 'brand': brand,
        if (partNumber.isNotEmpty) 'part_number': partNumber,
        'stock_quantity': stock.toString(),
      },
      fileBytes: imageBytes != null ? {'main_image': imageBytes} : null,
      fileNames: imageName != null ? {'main_image': imageName} : null,
      token: token,
    );
  }

  static Future<Map<String, dynamic>> updateSparePart({
    required int id,
    required String name,
    required String description,
    required double price,
    String brand = "",
    String partNumber = "",
    int stock = 0,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    return await ApiService.postMultipart(
      'admin/spare-parts/$id/update/',
      fields: {
        'name': name,
        'description': description,
        'price': price.toStringAsFixed(2),
        if (brand.isNotEmpty) 'brand': brand,
        if (partNumber.isNotEmpty) 'part_number': partNumber,
        'stock_quantity': stock.toString(),
      },
      fileBytes: imageBytes != null ? {'main_image': imageBytes} : null,
      fileNames: imageName != null ? {'main_image': imageName} : null,
      token: token,
    );
  }

  static Future<void> deleteSparePart(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    await ApiService.delete('admin/spare-parts/$id/delete/', token: token);
  }

  // ============ SERVICES CRUD ============
  // ============ CONTACT MESSAGES ============
  /// Pata contact messages zote.
  static Future<List<dynamic>> getContactMessages({String? status}) async {
    final token = await AdminTokenStorage.getAccessToken();
    final endpoint = status != null
        ? 'admin/contact/?status=$status'
        : 'admin/contact/';
    final data = await ApiService.get(endpoint, token: token);
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  /// Futa contact message.
  static Future<Map<String, dynamic>> deleteContactMessage(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.delete(
      'admin/contact/$id/',
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<List<dynamic>> getServices() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('services/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> createService({
    required String name,
    required String description,
    required double basePrice,
    int estimatedMinutes = 60,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'services/',
      {
        'name': name,
        'description': description,
        'base_price': basePrice.toStringAsFixed(2),
        'estimated_duration_minutes': estimatedMinutes,
        'is_active': true,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> updateService({
    required int id,
    required String name,
    required String description,
    required double basePrice,
    int estimatedMinutes = 60,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.patch(
      'services/$id/',
      {
        'name': name,
        'description': description,
        'base_price': basePrice.toStringAsFixed(2),
        'estimated_duration_minutes': estimatedMinutes,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> deleteService(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    await ApiService.delete('services/$id/', token: token);
  }

  // ============ NEWS CRUD ============
  static Future<List<dynamic>> getNews() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('news/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> updateNews({
    required int id,
    required String title,
    required String content,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.patch(
      'news/$id/',
      {'title': title, 'content': content},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> deleteNews(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    await ApiService.delete('news/$id/', token: token);
  }

  // ============ ADVERTISEMENTS CRUD ============
  static Future<List<dynamic>> getAds() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('advertisements/', token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> updateAd({
    required int id,
    required String title,
    required String description,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.patch(
      'advertisements/$id/',
      {'title': title, 'description': description},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> deleteAd(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    await ApiService.delete('advertisements/$id/', token: token);
  }

  // ============ ADMIN USER EDIT ============
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    String? role,
    bool? isActive,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final Map<String, dynamic> body = {};
    if (firstName != null) body['first_name'] = firstName;
    if (middleName != null) body['middle_name'] = middleName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone_number'] = phone;
    if (role != null) body['role'] = role;
    if (isActive != null) body['is_active'] = isActive;
    final data = await ApiService.patch(
      'accounts/admin/users/$id/',
      body,
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

}

class AdminBookingAPI {
  static Future<List<dynamic>> list({String? status}) async {
    final token = await AdminTokenStorage.getAccessToken();
    final q = status != null ? "?status=$status" : "";
    final data = await ApiService.get("admin/bookings/$q", token: token);
    if (data is Map && data["data"] is List) return data["data"];
    return [];
  }

  static Future<Map<String, dynamic>> assignMechanic({
    required int bookingId,
    required int mechanicId,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      "admin/bookings/$bookingId/assign-mechanic/",
      {"mechanic_id": mechanicId},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> updateStatus({
    required int bookingId,
    required String status,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      "admin/bookings/$bookingId/status/",
      {"status": status},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}

class AdminPaymentAPI {
  static Future<List<dynamic>> list({String? status}) async {
    final token = await AdminTokenStorage.getAccessToken();
    final q = status != null ? "?status=$status" : "";
    final data = await ApiService.get("admin/payments/$q", token: token);
    if (data is Map && data["data"] is List) return data["data"];
    return [];
  }

  static Future<Map<String, dynamic>> verify(
    int paymentId, {
    String action = 'verify',
    String? reason,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final body = <String, dynamic>{'action': action};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    final data = await ApiService.post(
      "admin/payments/$paymentId/verify/",
      body,
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


// =================== ADMIN SPARE PARTS API ===================
class AdminSparePartAPI {
  /// Orodha ya spare parts zote
  static Future<List<dynamic>> list() async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.get('admin/spare-parts/all/', token: token);
    if (data is Map && data['data'] is List) return data['data'] as List;
    return [];
  }

  /// Unda spare part (na image bytes — inafanya kazi Web + Mobile)
  static Future<Map<String, dynamic>> create({
    required String name,
    required String price,
    required String stockQuantity,
    required String condition,
    required String partNumber,
    required String description,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final fields = {
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'condition': condition,
      'part_number': partNumber,
      'description': description,
    };

    Map<String, List<int>>? fileBytes;
    Map<String, String>? fileNames;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      fileBytes = {'main_image': imageBytes};
      fileNames = {'main_image': imageName ?? 'spare_part.jpg'};
    }

    return await ApiService.postMultipart(
      'admin/spare-parts/create/',
      fields: fields,
      fileBytes: fileBytes,
      fileNames: fileNames,
      token: token,
    );
  }

  /// Delete spare part
  static Future<Map<String, dynamic>> delete(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.delete(
      'admin/spare-parts/$id/delete/',
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


// =================== ADMIN MECHANIC API ===================
class AdminMechanicAPI {
  static Future<Map<String, dynamic>> create({
    required String fullName,
    required String phone,
    required String specialist,
    required String region,
    String district = '',
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'admin/mechanics/create/',
      {
        'full_name': fullName,
        'phone': phone,
        'specialist': specialist,
        'region': region,
        'district': district,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> delete(int id) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.delete(
      'admin/mechanics/$id/delete/',
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


// =================== ADMIN ORDER API ===================
class AdminOrderAPI {
  /// Oda zote.
  static Future<List<dynamic>> list({String? status}) async {
    final token = await AdminTokenStorage.getAccessToken();
    final endpoint = status != null && status != 'ALL'
        ? 'spare-parts/admin/orders/all/?status=$status'
        : 'spare-parts/admin/orders/all/';
    final data = await ApiService.get(endpoint, token: token);
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  /// Badilisha status ya oda.
  static Future<Map<String, dynamic>> updateStatus({
    required int orderId,
    required String status,
    String adminNotes = '',
  }) async {
    final token = await AdminTokenStorage.getAccessToken();
    final data = await ApiService.post(
      'spare-parts/admin/orders/$orderId/status/',
      {'status': status, 'admin_notes': adminNotes},
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}

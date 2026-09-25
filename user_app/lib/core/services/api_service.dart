import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// =================== TOKEN STORAGE ===================
class TokenStorage {
  static const _accessKey = 'user_access_token';
  static const _refreshKey = 'user_refresh_token';
  static const _loginTimeKey = 'user_login_time';
  static const _userKey = 'user_data';

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
    return (elapsed / 60000) > AppConstants.userSessionMinutes;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_loginTimeKey);
    await prefs.remove(_userKey);
    // Futa kila kitu ili credentials zisiokolewe
    await prefs.clear();
  }
}

// =================== API SERVICE ===================
class ApiService {
  /// POST multipart — kwa kupakia files (bytes, web-compatible)
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

  /// DELETE request — kufuta resource.
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

  /// PATCH multipart - inafanya kazi web na mobile (bytes).
  static Future<dynamic> patchMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, List<int>>? fileBytes,
    Map<String, String>? fileNames,
    String? token,
  }) async {
    final uri = Uri.parse(AppConstants.baseUrl + endpoint);
    final request = http.MultipartRequest('PATCH', uri);
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
    if (data is Map) {
      // 1. DRF pagination: {results: [...]}
      if (data['results'] is List) return data['results'];
      // 2. Custom pagination 1: {data: [...]}
      if (data['data'] is List) return data['data'];
      // 3. Custom pagination 2: {data: {items: [...]}} ← BACKEND YETU
      if (data['data'] is Map) {
        final inner = data['data'] as Map;
        if (inner['items'] is List) return inner['items'];
        if (inner['results'] is List) return inner['results'];
      }
      // 4. Direct items: {items: [...]}
      if (data['items'] is List) return data['items'];
    }
    return [];
  }
}

// =================== PUBLIC API ===================
class PublicAPI {
  static Future<List<dynamic>> getAdvertisements() async =>
      ApiService.asList(await ApiService.get('advertisements/'));

  static Future<List<dynamic>> getNews() async =>
      ApiService.asList(await ApiService.get('news/'));

  static Future<List<dynamic>> getServices() async =>
      ApiService.asList(await ApiService.get('services/'));

  static Future<List<dynamic>> getSpareParts() async =>
      ApiService.asList(await ApiService.get('spare-parts/'));
}

// =================== AUTH API ===================
class AuthAPI {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final raw = await ApiService.post('auth/login/', {
      'email': email,
      'password': password,
    });

    // Response: {success, message, data: {access, refresh, user}}
    Map<String, dynamic> data;
    if (raw is Map && raw['data'] is Map && raw['data']['access'] != null) {
      data = Map<String, dynamic>.from(raw['data'] as Map);
    } else if (raw is Map && raw['access'] != null) {
      data = Map<String, dynamic>.from(raw);
    } else {
      data = Map<String, dynamic>.from(raw as Map);
    }

    if (data['access'] != null) {
      await TokenStorage.saveTokens(
        data['access'].toString(),
        data['refresh']?.toString() ?? '',
      );
      // Save user data kutoka response
      if (data['user'] is Map) {
        await TokenStorage.saveUser(
          Map<String, dynamic>.from(data['user'] as Map),
        );
      } else {
        try {
          final profile = await getProfile();
          await TokenStorage.saveUser(profile);
        } catch (_) {}
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    String middleName = '',
    String region = '',
    String vehicleMake = '',
    String vehicleModel = '',
    String vehicleYear = '',
    String vehicleRegistration = '',
  }) async {
    final body = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phone,
      'password': password,
    };
    if (middleName.isNotEmpty) body['middle_name'] = middleName;
    if (region.isNotEmpty) body['region'] = region;
    if (vehicleMake.isNotEmpty) body['vehicle_make'] = vehicleMake;
    if (vehicleModel.isNotEmpty) body['vehicle_model'] = vehicleModel;
    if (vehicleYear.isNotEmpty) {
      body['vehicle_year'] = int.tryParse(vehicleYear) ?? vehicleYear;
    }
    if (vehicleRegistration.isNotEmpty) {
      body['vehicle_registration'] = vehicleRegistration;
    }
    final data = await ApiService.post('auth/register/', body);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final data = await ApiService.post(
      'auth/password-reset/request/',
      {'email': email},
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> verifyResetCode(
    String email,
    String code,
  ) async {
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

  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final data = await ApiService.post('auth/google/', {'id_token': idToken});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.getAccessToken();
    final raw = await ApiService.get('users/profile/', token: token);
    if (raw is Map && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    return Map<String, dynamic>.from(raw as Map);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? phone,
    List<int>? profileImageBytes,
    String? profileImageName,
    Map<String, dynamic>? vehicle,
  }) async {
    final token = await TokenStorage.getAccessToken();

    final fields = <String, String>{};
    if (firstName != null) fields['first_name'] = firstName;
    if (middleName != null) fields['middle_name'] = middleName;
    if (lastName != null) fields['last_name'] = lastName;
    if (phone != null) fields['phone_number'] = phone;
    if (vehicle != null) {
      fields['vehicle_make'] = vehicle['make'] ?? '';
      fields['vehicle_model'] = vehicle['model'] ?? '';
      fields['vehicle_year'] = vehicle['year']?.toString() ?? '';
      fields['vehicle_registration'] = vehicle['registration_number'] ?? '';
    }

    if (profileImageBytes == null) {
      final body = <String, dynamic>{};
      for (final e in fields.entries) {
        body[e.key] = e.value;
      }
      final data = await ApiService.patch(
        'users/profile/',
        body,
        token: token,
      );
      return Map<String, dynamic>.from(data as Map);
    }

    final data = await ApiService.patchMultipart(
      'users/profile/',
      fields: fields,
      fileBytes: {'profile_image': profileImageBytes},
      fileNames: {'profile_image': profileImageName ?? 'avatar.jpg'},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}

// =================== METHODS API ===================
class MethodsAPI {
  static Future<List<dynamic>> getMechanics({
    bool onlyAvailable = false,
    String? region,
  }) async {
    final params = <String>[];
    if (onlyAvailable) params.add('available=true');
    if (region != null && region.isNotEmpty) {
      params.add('region=${Uri.encodeComponent(region)}');
    }
    final q = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await ApiService.get('mechanics/$q');
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> diagnose({
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleYear,
    required String symptoms,
    String additionalInfo = '',
  }) async {
    final data = await ApiService.post('diagnosis/service/', {
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
      'symptoms': symptoms,
      'additional_info': additionalInfo,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  /// AI Diagnosis na picha (multipart).

  /// Conversational AI diagnosis — multi-turn chat (with persistence).
  static Future<Map<String, dynamic>> diagnosisChat({
    required String message,
    String vehicleMake = '',
    String vehicleModel = '',
    String vehicleYear = '',
    int? conversationId,
    List<int>? imageBytes,
    String? imageName,
  }) async {
    Map<String, List<int>>? fileBytes;
    Map<String, String>? fileNames;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      fileBytes = {'image': imageBytes};
      fileNames = {'image': imageName ?? 'car_part.jpg'};
    }
    final fields = <String, String>{
      'message': message,
      'vehicle_make': vehicleMake,
      'vehicle_model': vehicleModel,
      'vehicle_year': vehicleYear,
    };
    if (conversationId != null) {
      fields['conversation_id'] = conversationId.toString();
    }
    final data = await ApiService.postMultipart(
      'diagnosis/chat/',
      fields: fields,
      fileBytes: fileBytes,
      fileNames: fileNames,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Pata conversation ya mwisho ya user.
  static Future<Map<String, dynamic>?> diagnosisChatHistory() async {
    try {
      final data = await ApiService.get('diagnosis/chat/');
      final map = Map<String, dynamic>.from(data as Map);
      final inner = map['data'];
      if (inner == null) return null;
      return Map<String, dynamic>.from(inner as Map);
    } catch (_) {
      return null;
    }
  }

  /// Futa conversation (anza upya).
  static Future<void> diagnosisChatReset() async {
    try {
      await ApiService.delete('diagnosis/chat/');
    } catch (_) {}
  }

  /// Unda DiagnosisSession mpya.
  static Future<Map<String, dynamic>> createSession({
    required int vehicleId,
    required String adapterName,
    required String protocol,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'diagnosis/scans/create_with_payment/',
      {
        'vehicle': vehicleId,
        'adapter_name': adapterName,
        'protocol': protocol,
        'source': 'OBD',
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Tuma DTCs na live data kwa backend kuchambua.
  static Future<Map<String, dynamic>> processScan({
    required int sessionId,
    required List<String> dtcCodes,
    required Map<String, num> liveData,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'diagnosis/scans/$sessionId/process/',
      {
        'responses': {
          'raw_dtc_response': dtcCodes.isEmpty ? '430000' : '43${dtcCodes.length}',
        },
        'live_data': liveData,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Chukua ripoti kamili ya scan.
  static Future<Map<String, dynamic>> getReport(int sessionId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'diagnosis/scans/$sessionId/report/',
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Chukua historia ya scans.
  static Future<List<dynamic>> getHistory() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'diagnosis/scans/',
      token: token,
    );
    return ApiService.asList(data);
  }
}


// =================== CONTACT API ===================
class WalletAPI {
  static Future<Map<String, dynamic>> getWallet() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('wallet/', token: token);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getTransactions() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('transactions/', token: token);
    return ApiService.asList(data);
  }
}


// =================== OBD API ===================
class ObdAPI {
  /// Unda DiagnosisSession mpya.
  static Future<Map<String, dynamic>> createSession({
    required int vehicleId,
    required String adapterName,
    required String protocol,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'diagnosis/scans/create_with_payment/',
      {
        'vehicle': vehicleId,
        'adapter_name': adapterName,
        'protocol': protocol,
        'source': 'OBD',
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Tuma DTCs na live data kwa backend kuchambua.
  static Future<Map<String, dynamic>> processScan({
    required int sessionId,
    required List<String> dtcCodes,
    required Map<String, num> liveData,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'diagnosis/scans/$sessionId/process/',
      {
        'responses': {
          'raw_dtc_response': dtcCodes.isEmpty ? '430000' : '43${dtcCodes.length}',
        },
        'live_data': liveData,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Chukua ripoti kamili ya scan.
  static Future<Map<String, dynamic>> getReport(int sessionId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'diagnosis/scans/$sessionId/report/',
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Chukua historia ya scans.
  static Future<List<dynamic>> getHistory() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'diagnosis/scans/',
      token: token,
    );
    return ApiService.asList(data);
  }
}


// =================== CONTACT API ===================

class ContactAPI {
  static Future<Map<String, dynamic>> sendMessage({
    required String fullName,
    required String email,
    required String message,
    String phone = "",
    String subject = "",
  }) async {
    final data = await ApiService.post("contact/", {
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "subject": subject,
      "message": message,
    });
    return Map<String, dynamic>.from(data as Map);
  }
}

// =================== PAYMENT API ===================
class PaymentAPI {
  /// Unified payment — inatumika kwa kila kitu (OBD, bookings, services, spare parts).
  /// Mfumo unatambua mtandao (Vodacom, Tigo, Airtel, Halotel, TTCL) au benki (NMB, CRDB, n.k.)
  static Future<Map<String, dynamic>> initiateUnified({
    required double amount,
    required String purpose,
    required String methodType, // 'MOBILE_MONEY' au 'BANK'
    required String identifier, // phone number au account/card
    String? networkOverride, // mfano 'Vodacom', 'Tigo/Yas' — kama user anabadilisha
    String? bankOverride, // mfano 'NMB', 'CRDB' — kama user anabadilisha
    String description = "",
    String referenceId = "",
  }) async {
    final token = await TokenStorage.getAccessToken();
    final body = <String, dynamic>{
      "amount": amount.toStringAsFixed(2),
      "purpose": purpose,
      "method_type": methodType,
      "identifier": identifier,
      "description": description,
      "reference_id": referenceId,
    };
    if (networkOverride != null && networkOverride.isNotEmpty) {
      body["network_override"] = networkOverride;
    }
    if (bankOverride != null && bankOverride.isNotEmpty) {
      body["bank_override"] = bankOverride;
    }
    final data = await ApiService.post(
      "payments/unified/initiate/",
      body,
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Legacy method — inatumika kwa compatibility.
  static Future<Map<String, dynamic>> initiate({
    required double amount,
    required String purpose,
    required String phoneNumber,
    String description = "",
    String referenceId = "",
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      "payments/initiate/",
      {
        "amount": amount.toStringAsFixed(2),
        "purpose": purpose,
        "phone_number": phoneNumber,
        "description": description,
        "reference_id": referenceId,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> getMyPayments() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get("payments/my/", token: token);
    if (data is Map && data["data"] is List) {
      return data["data"] as List;
    }
    return [];
  }

  static Future<Map<String, dynamic>> getDetail(int id) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get("payments/$id/", token: token);
    return Map<String, dynamic>.from(data as Map);
  }

  /// User anaweka reference ya M-Pesa/Tigo baada ya kulipa
  static Future<Map<String, dynamic>> submitReference({
    required int paymentId,
    required String userReference,
    String note = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      "payments/$paymentId/submit-reference/",
      {
        "user_reference": userReference,
        "note": note,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


// =================== BOOKING API ===================
class BookingAPI {
  /// Booking moja (detail).
  static Future<Map<String, dynamic>> getDetail(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'bookings/$bookingId/',
      token: token,
    );
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Pata countdown ya booking (remaining_seconds, hours, minutes).
  static Future<Map<String, dynamic>> getCountdown(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'bookings/$bookingId/countdown/',
      token: token,
    );
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<Map<String, dynamic>> create({
    required int vehicleId,
    required int serviceId,
    required String scheduledDate,
    required String scheduledTime,
    String bookingType = "GARAGE",
    String notes = "",
    String region = "",
    String district = "",
    String serviceAddress = "",
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      "bookings/create/",
      {
        "vehicle": vehicleId,
        "service": serviceId,
        "scheduled_date": scheduledDate,
        "scheduled_time": scheduledTime,
        "booking_type": bookingType,
        "customer_notes": notes,
        "region": region,
        "district": district,
        "service_address": serviceAddress,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<dynamic>> myBookings() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get("bookings/my/", token: token);
    if (data is Map && data["data"] is List) {
      return data["data"] as List;
    }
    return [];
  }

  static Future<Map<String, dynamic>> payDeposit({
    required int bookingId,
    required String phoneNumber,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      "bookings/$bookingId/pay-deposit/",
      {"phone_number": phoneNumber},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> finalPayment({
    required int bookingId,
    required String phoneNumber,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      "bookings/$bookingId/final-payment/",
      {"phone_number": phoneNumber},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


// =================== NOTIFICATION API ===================
class NotificationAPI {
  static Future<void> registerDeviceToken(String fcmToken) async {
    final token = await TokenStorage.getAccessToken();
    await ApiService.post(
      'notifications/devices/register/',
      {'device_token': fcmToken, 'device_type': 'web'},
      token: token,
    );
  }

  static Future<List<dynamic>> getMyNotifications() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get("notifications/", token: token);
    return ApiService.asList(data);
  }

  static Future<Map<String, dynamic>> markAsRead(int id) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.patch(
      "notifications/$id/",
      {"is_read": true},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getMyNotifications();
      int count = 0;
      for (final n in notifications) {
        if (n is Map && n['is_read'] != true) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ============ ADDITIONAL METHODS ============
  static Future<Map<String, dynamic>> markAllRead() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('notifications/mark-all-read/', {}, token: token);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> deleteOne(int id) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.delete('notifications/$id/', token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<Map<String, dynamic>> deleteAll() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.delete('notifications/delete-all/', token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}


// =================== CHAT API ===================
class ChatAPI {
  /// Upload attachment (image, video, audio, document) kwenye message.
  static Future<Map<String, dynamic>> uploadAttachment({
    required int messageId,
    required List<int> bytes,
    required String fileName,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.postMultipart(
      'chat/attachments/',
      fields: {'message_id': messageId.toString()},
      fileBytes: {'file': bytes},
      fileNames: {'file': fileName},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }


  // ============ "I'M READY" FLOW ============
  static Future<Map<String, dynamic>> sendReady({
    required int roomId,
    double? userLat,
    double? userLng,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/ready/',
      {
        if (userLat != null) 'user_latitude': userLat,
        if (userLng != null) 'user_longitude': userLng,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> acceptReady({
    required int roomId,
    double? mechLat,
    double? mechLng,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/accept-ready/',
      {
        if (mechLat != null) 'mechanic_latitude': mechLat,
        if (mechLng != null) 'mechanic_longitude': mechLng,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> cancelReady(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/cancel-ready/', {}, token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> confirmArrival({
    required int roomId,
    required bool confirmed,
    String feedback = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/confirm-arrival/',
      {'confirmed': confirmed, 'feedback': feedback},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getReadyStatus(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'chat/rooms/$roomId/ready-status/', token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  // ============ BOOKING APPROVAL ============
  static Future<Map<String, dynamic>> requestApproval(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/request-approval/',
      {},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> approveUser({
    required int roomId,
    required String action,
    String note = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/approve-user/',
      {'action': action, 'note': note},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getApprovalStatus(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'chat/rooms/$roomId/approval-status/', token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }



  /// Pata mechanics waliopo available kwa chat.
  static Future<List<dynamic>> getAvailableMechanics() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('mechanics/?available=true', token: token);
    if (data is Map && data['data'] is Map && data['data']['items'] is List) {
      return data['data']['items'] as List;
    }
    if (data is Map && data['data'] is List) return data['data'];
    if (data is List) return data;
    return [];
  }


  /// Orodha ya chat rooms za user.
  static Future<List<dynamic>> getRooms() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('chat/rooms/', token: token);
    // Format 1: {success, data: {items: [...]}}
    if (data is Map &&
        data['data'] is Map &&
        data['data']['items'] is List) {
      return data['data']['items'] as List;
    }
    // Format 2: {data: [...]}
    if (data is Map && data['data'] is List) return data['data'];
    // Format 3: [...] directly
    if (data is List) return data;
    // Format 4: {results: [...]} (paginated)
    if (data is Map && data['results'] is List) return data['results'];
    return [];
  }

  /// Messages za room fulani.
  static Future<List<dynamic>> getMessages(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('chat/rooms/$roomId/messages/', token: token);
    if (data is Map && data['data'] is Map && data['data']['messages'] is List) {
      return data['data']['messages'];
    }
    if (data is Map && data['data'] is List) return data['data'];
    if (data is List) return data;
    return [];
  }

  /// Tuma message mpya.
  static Future<Map<String, dynamic>> sendMessage({
    required int roomId,
    required String content,
    String messageType = 'text',
    int? replyTo,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('chat/messages/', {
      'room': roomId,
      'content': content,
      'message_type': messageType,
      if (replyTo != null) 'reply_to': replyTo,
    }, token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Mark messages zote kwenye room kama read.
  static Future<void> markRead(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    await ApiService.post('chat/rooms/$roomId/mark_read/', {}, token: token);
  }

  /// Delete message (soft delete).
  static Future<Map<String, dynamic>> deleteMessage(int messageId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/messages/$messageId/delete-message/',
      {},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Edit message.
  static Future<Map<String, dynamic>> editMessage({
    required int messageId,
    required String content,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/messages/$messageId/edit-message/',
      {'content': content},
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Futa room.
  static Future<Map<String, dynamic>> deleteRoom(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.delete('chat/rooms/$roomId/', token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Tengeneza room mpya.
  static Future<Map<String, dynamic>> createRoom({
    required int otherUserId,
    int? bookingId,
    String roomType = 'direct',
    String? name,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('chat/rooms/', {
      'room_type': roomType,
      'name': name ?? 'Chat',
      'participant_ids': [otherUserId],
      if (bookingId != null) 'booking': bookingId,
    }, token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}


// =================== SPARE PART ORDER API ===================
class SparePartOrderAPI {
  /// Unda oda mpya (PENDING_PAYMENT).
  static Future<Map<String, dynamic>> create({
    required int sparePartId,
    int quantity = 1,
    String contactPhone = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('spare-parts/orders/create/', {
      'spare_part_id': sparePartId,
      'quantity': quantity,
      'contact_phone': contactPhone,
    }, token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Oda zote za user.
  static Future<List<dynamic>> myOrders() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('spare-parts/orders/my/', token: token);
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  /// Oda moja.
  static Future<Map<String, dynamic>> detail(int orderId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'spare-parts/orders/$orderId/',
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Weka delivery details baada ya payment.
  static Future<Map<String, dynamic>> updateDelivery({
    required int orderId,
    required String deliveryType,
    String deliveryLocation = '',
    String deliveryRegion = '',
    String? deliveryDate,
    String deliveryTime = '',
    String deliveryNotes = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final body = <String, dynamic>{
      'delivery_type': deliveryType,
      'delivery_location': deliveryLocation,
      'delivery_region': deliveryRegion,
      'delivery_time': deliveryTime,
      'delivery_notes': deliveryNotes,
    };
    if (deliveryDate != null && deliveryDate.isNotEmpty) {
      body['delivery_date'] = deliveryDate;
    }
    final data = await ApiService.patch(
      'spare-parts/orders/$orderId/delivery/',
      body,
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Futa oda.
  static Future<void> delete(int orderId) async {
    final token = await TokenStorage.getAccessToken();
    await ApiService.delete(
      'spare-parts/orders/$orderId/delete/',
      token: token,
    );
  }
}


// =================== OBD API ===================
class OBDAPI {
  /// Anzisha malipo ya OBD (30,000 TZS).
  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'diagnosis/obd-payment/initiate/',
      {'phone_number': phoneNumber},
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Angalia kama user ameshalipia OBD.
  static Future<bool> hasPaid() async {
    try {
      final token = await TokenStorage.getAccessToken();
      final data = await ApiService.get(
        'diagnosis/history/',
        token: token,
      );
      // Kama tuna data — inamaanisha alishalipia
      if (data is Map && data['data'] != null) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}

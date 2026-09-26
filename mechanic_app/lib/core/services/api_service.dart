import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}

class ApiService {
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? token}) async {
    final response = await http.post(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<dynamic> get(String endpoint, {String? token}) async {
    final response = await http.get(
      Uri.parse(AppConstants.baseUrl + endpoint),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handleResponse(response);
  }

  static Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, List<int>>? fileBytes,
    Map<String, String>? fileNames,
    String? token,
  }) async {
    final uri = Uri.parse(AppConstants.baseUrl + endpoint);
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);
    if (fileBytes != null) {
      for (final entry in fileBytes.entries) {
        final filename = fileNames?[entry.key] ?? 'upload.bin';
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
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    // 401 = Session imeisha
    if (response.statusCode == 401) {
      throw Exception('Session imeisha. Tafadhali ingia tena.');
    }

    // 403 = Huna ruhusa
    if (response.statusCode == 403) {
      throw Exception('Huna ruhusa ya kufanya hili.');
    }

    // 404 = Haipo
    if (response.statusCode == 404) {
      throw Exception('Haipatikani.');
    }

    // 500 = Server error
    if (response.statusCode >= 500) {
      throw Exception('Server ina shida. Jaribu tena baadaye.');
    }

    // Nyingine — toa message safi
    try {
      final error = jsonDecode(response.body);
      final msg = error['detail'] ?? error['message'] ?? 'Hitilafu imetokea';
      throw Exception(msg.toString());
    } catch (e) {
      throw Exception('Hitilafu imetokea (${response.statusCode})');
    }
  }
}

class AuthAPI {

  /// Mechanic ana-activate account (admin-created) kwa ME-XXXX
  static Future<Map<String, dynamic>> activate({
    required String registrationNumber,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String region = '',
  }) async {
    final res = await ApiService.post('mechanics/activate/', {
      'registration_number': registrationNumber,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password': password,
      'region': region,
    });

    if (res is Map && res['success'] == true && res['data'] is Map) {
      final data = res['data'] as Map;
      if (data['access'] != null) {
        await TokenStorage.saveTokens(
          data['access'].toString(),
          data['refresh']?.toString() ?? '',
        );
      }
      return Map<String, dynamic>.from(data);
    }
    throw Exception(
      (res is Map ? res['message']?.toString() : null) ?? 'Activation imeshindwa',
    );
  }

  /// Login kwa ME-XXXX au email + password
  static Future<Map<String, dynamic>> loginByIdentifier(
    String identifier,
    String password,
  ) async {
    final res = await ApiService.post(
      'mechanics/login/',
      {'identifier': identifier, 'password': password},
    );

    if (res is Map && res['success'] == true && res['data'] is Map) {
      final data = res['data'] as Map;
      if (data['access'] != null) {
        await TokenStorage.saveTokens(
          data['access'].toString(),
          data['refresh']?.toString() ?? '',
        );
      }
      return Map<String, dynamic>.from(data);
    }
    throw Exception(
      (res is Map ? res['message']?.toString() : null) ?? 'Login imeshindwa',
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String registrationNumber,
    required String phone,
    required String newPassword,
  }) async {
    final res = await ApiService.post('mechanics/reset-password/', {
      'registration_number': registrationNumber,
      'phone': phone,
      'new_password': newPassword,
    });

    if (res is Map && res['success'] == true) {
      return Map<String, dynamic>.from(res);
    }
    throw Exception(
      (res is Map ? res['message']?.toString() : null) ?? 'Reset imeshindwa',
    );
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiService.post('auth/login/', {'email': email, 'password': password});
    if (data is Map && data.containsKey('access')) {
      await TokenStorage.saveTokens(data['access'], data['refresh']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> registerMechanic({
    required String fullName,
    required String email,
    required String phone,
    required String regNo,
    required String specialization,
    required String password,
  }) async {
    return await ApiService.post('mechanics/register/mechanic/', {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'registration_number': regNo,
      'specialization': specialization,
      'password': password,
    });
  }
}

class JobsAPI {
  static Future<List<dynamic>> getAvailableJobs() async {
    final token = await TokenStorage.getAccessToken();
    final res = await ApiService.get('bookings/jobs/available/', token: token);
    if (res is Map) {
      if (res['data'] is List) return res['data'] as List;
      if (res['results'] is List) return res['results'] as List;
    }
    if (res is List) return res;
    return [];
  }

  static Future<Map<String, dynamic>> requestJob(String jobId) async {
    final token = await TokenStorage.getAccessToken();
    return await ApiService.post('bookings/jobs/$jobId/request/', {}, token: token);
  }

  static Future<Map<String, dynamic>> acceptJob(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('bookings/$bookingId/mechanic-accept/', {}, token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  static Future<Map<String, dynamic>> rejectJob(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post('bookings/$bookingId/mechanic-reject/', {}, token: token);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}

class EarningsAPI {
  static Future<Map<String, dynamic>> getEarnings() async {
    final token = await TokenStorage.getAccessToken();
    return await ApiService.get('payments/earnings/', token: token);
  }
}

class ReviewsAPI {
  static Future<List<dynamic>> getReviews() async {
    final token = await TokenStorage.getAccessToken();
    return await ApiService.get('reviews/mechanic/', token: token);
  }
}

class ProfileAPI {
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenStorage.getAccessToken();
    return await ApiService.get('mechanics/profile/', token: token);
  }
}

class NotificationAPI {
  static Future<void> registerDeviceToken(String fcmToken) async {
    final token = await TokenStorage.getAccessToken();
    await ApiService.post('notifications/devices/register/', {'device_token': fcmToken, 'device_type': 'web'}, token: token);
  }
}


// =================== MECHANIC API ===================
class MechanicAPI {
  /// Toggle online/offline
  static Future<Map<String, dynamic>> toggleAvailability({bool? isAvailable}) async {
    final token = await TokenStorage.getAccessToken();
    final body = <String, dynamic>{};
    if (isAvailable != null) body['is_available'] = isAvailable;

    final res = await ApiService.post(
      'mechanics/toggle-availability/',
      body,
      token: token,
    );
    return res is Map ? Map<String, dynamic>.from(res) : {};
  }

  /// Kazi zangu (assigned)
  static Future<List<dynamic>> getMyJobs() async {
    final token = await TokenStorage.getAccessToken();
    final res = await ApiService.get('mechanics/my-jobs/', token: token);
    if (res is Map && res['data'] is List) return res['data'] as List;
    return [];
  }

  /// Kazi zilizopo (pending)
  static Future<List<dynamic>> getAvailableJobs() async {
    final token = await TokenStorage.getAccessToken();
    final res = await ApiService.get('bookings/jobs/available/', token: token);
    if (res is Map && res['data'] is List) return res['data'] as List;
    if (res is List) return res;
    return [];
  }

  /// Omba kazi
  static Future<Map<String, dynamic>> requestJob(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final res = await ApiService.post(
      'bookings/jobs/$bookingId/request/',
      {},
      token: token,
    );
    return res is Map ? Map<String, dynamic>.from(res) : {};
  }
}


class ChatAPI {
  /// Orodha ya chat rooms za mechanic.
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
    // Format 4: {results: [...]}
    if (data is Map && data['results'] is List) return data['results'];
    return [];
  }

  /// Messages za room fulani.
  static Future<List<dynamic>> getMessages(int roomId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('chat/rooms/$roomId/messages/', token: token);
    // Format 1: {success, data: {messages: [...], total, ...}}
    if (data is Map && data['data'] is Map && data['data']['messages'] is List) {
      return data['data']['messages'];
    }
    // Format 2: {data: [...]}
    if (data is Map && data['data'] is List) return data['data'];
    // Format 3: [...] directly
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

  /// Upload attachment (image, video, audio, document).
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

  /// Tengeneza room mpya (kama haipo).
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

  // ============ "I'M READY" FLOW ============
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

}


// =================== BOOKING MECHANIC API ===================
  /// Tuma location ya user/mechanic kwenye chat room.
  static Future<Map<String, dynamic>> shareLocation({
    required int roomId,
    required double latitude,
    required double longitude,
    String address = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/share-location/',
      {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  

  /// Tuma location ya user/mechanic kwenye chat room.
  static Future<Map<String, dynamic>> shareLocation({
    required int roomId,
    required double latitude,
    required double longitude,
    String address = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'chat/rooms/$roomId/share-location/',
      {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
      token: token,
    );
    return Map<String, dynamic>.from(data as Map);
  }
}


class BookingMechanicAPI {
  /// Bookings zilizo PENDING (requests).
  static Future<List<dynamic>> pendingBookings() async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get('bookings/mechanic/pending/', token: token);
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is List) return data;
    return [];
  }

  /// Kubali booking + weka ETA.
  static Future<Map<String, dynamic>> acceptBooking({
    required int bookingId,
    required int travelHours,
    int travelMinutes = 0,
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'bookings/$bookingId/accept/',
      {'travel_hours': travelHours, 'travel_minutes': travelMinutes},
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Kataa booking.
  static Future<Map<String, dynamic>> rejectBooking({
    required int bookingId,
    String reason = '',
  }) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.post(
      'bookings/$bookingId/reject/',
      {'reason': reason},
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// Countdown info.
  static Future<Map<String, dynamic>> getCountdown(int bookingId) async {
    final token = await TokenStorage.getAccessToken();
    final data = await ApiService.get(
      'bookings/$bookingId/countdown/',
      token: token,
    );
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
}
